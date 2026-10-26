import pathlib
import os, sys
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from sampler.sampling_utils import read_char_tsv, get_param2tsv, get_samples
from sampler.run_sampler import sample_param, sample_all, take_samples_per_segment
from collections import Counter
import pandas as pd
import polars as pl
import tempfile
import yaml
import random
random.seed(42)


def read_sampler_config() -> dict:
    config_path = pathlib.Path(__file__).parents[1] / 'sampler' / 'sampler_config.yaml'
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)


def make_segment_df(segment_sizes: dict[str, int]) -> pl.DataFrame:
    """One row per building, tagged with its segment and a building id unique across segments."""
    segments = [segment for segment, size in segment_sizes.items() for _ in range(size)]
    return pl.DataFrame({"segment": segments}).with_row_index("Building", offset=1)


def test_get_samples() -> None:
    samples = get_samples(probs=[1], options=["Yes"], num_samples=10)
    assert samples == ["Yes"]*10
    samples = get_samples(probs=[0.5, 0.5], options=["Yes", "No"], num_samples=400)
    yes_count = Counter(samples)['Yes']
    no_count = Counter(samples)['No']
    assert abs(yes_count - no_count) <= 20  # 5% of 400 = 20
    assert yes_count + no_count == 400

    samples = get_samples(probs=[0.5, 0.5], options=["Yes", "No"], num_samples=1)
    assert samples in [['No'], ['Yes']]

    # probabilities may not exactly sum to 1
    samples = get_samples(probs=[0.49, 0.49], options=["Yes", "No"], num_samples=400)
    yes_count = Counter(samples)['Yes']
    no_count = Counter(samples)['No']
    assert abs(yes_count - no_count) <= 20  # 5% of 400 = 20
    assert yes_count + no_count == 400


def test_sample_param():
    bedrooms_tsv = pd.DataFrame({'Option=1': [0.2], 'Option=2': [0.2], 'Option=3': [0.2], 'Option=4': [0.2],
                                 'Option=5': [0.2]})
    fan_tsv = pd.DataFrame({'Dependency=Bedrooms': [1, 2, 3, 4, 5],
                            'Option=None': [0.4] * 5,
                            'Option=Standard': [0.4] * 5,
                            'Option=Premium': [0.2] * 5})
    sample_df = pd.DataFrame({'Building': range(1, 101)})
    with tempfile.TemporaryDirectory() as tmp_dir:
        tsv_file = tmp_dir + "/Bedrooms.tsv"
        bedrooms_tsv.to_csv(tsv_file, sep='\t', index=False)
        tsv_tuple = read_char_tsv(pathlib.Path(tsv_file))
        samples = sample_param(param_tuple=tsv_tuple, sample_df=sample_df, param='Bedrooms', num_samples=100, random_seed=42)
        assert len(samples) == 100
        one_count = Counter(samples)['1']
        two_count = Counter(samples)['2']
        assert abs(one_count - two_count) <= 20
        sample_df['Bedrooms'] = samples
        tsv_file = tmp_dir + "/Ceiling Fan.tsv"
        fan_tsv.to_csv(tsv_file, sep='\t', index=False)
        tsv_tuple = read_char_tsv(pathlib.Path(tsv_file))
        samples = sample_param(param_tuple=tsv_tuple, sample_df=sample_df, param='Bedrooms', num_samples=100, random_seed=42)
        assert len(samples) == 100
        none_count = Counter(samples)['None']
        standard_count = Counter(samples)['Standard']
        assert abs(none_count - standard_count) <= 20
        sample_df['Fan'] = samples


def test_get_param2tsv():
    project_dir = pathlib.Path(__file__).parent / 'project_sampling_test'
    param2tsv = get_param2tsv(project_dir)
    assert len(param2tsv) == 3
    assert 'Bedrooms' in param2tsv
    assert 'Ceiling Fan' in param2tsv
    assert 'Uses AC' in param2tsv
    group2probs, dep_cols, opt_cols = param2tsv['Bedrooms']
    assert dep_cols == []
    assert opt_cols == ['1', '2', '3', '4', '5']
    assert len(group2probs) == 1
    assert group2probs[()] == [0.2] * 5
    group2probs, dep_cols, opt_cols = param2tsv['Ceiling Fan']
    assert dep_cols == ['Bedrooms']
    assert opt_cols == ['None', 'Standard', 'Premium']
    assert len(group2probs) == 5
    for group in ['1', '2', '3', '4', '5']:
        assert group2probs[(group,)] == [0.4, 0.4, 0.2]
    group2probs, dep_cols, opt_cols = param2tsv['Uses AC']
    assert dep_cols == ['Ceiling Fan']
    assert opt_cols == ['Yes', 'No']
    assert len(group2probs) == 3


def test_sample_all():
    project_dir = pathlib.Path(__file__).parent / 'project_sampling_test'
    sample_df = sample_all(project_dir, 10)
    assert len(sample_df) == 10


def test_take_keeps_the_asked_for_count_per_segment():
    df = make_segment_df({'a': 50, 'b': 7, 'c': 12})

    taken = take_samples_per_segment(df, ['segment'], 12)

    counts = dict(taken.group_by('segment').len().iter_rows())
    assert counts == {'a': 12, 'b': 7, 'c': 12}, "a short segment must contribute all its rows"
    assert taken['Building'].n_unique() == taken.height

    # The same frame taken at a different count follows the count, not a hardcoded 12
    smaller = take_samples_per_segment(df, ['segment'], 4)
    assert dict(smaller.group_by('segment').len().iter_rows()) == {'a': 4, 'b': 4, 'c': 4}


def test_take_is_reproducible_and_random_under_the_seed():
    df = make_segment_df({'a': 500})

    first = take_samples_per_segment(df, ['segment'], 12, random_seed=42)['Building'].to_list()
    repeat = take_samples_per_segment(df, ['segment'], 12, random_seed=42)['Building'].to_list()
    other = take_samples_per_segment(df, ['segment'], 12, random_seed=43)['Building'].to_list()

    assert first == repeat
    assert first != other

    # The take reaches past the head of the segment, so it does not depend on incoming row order
    assert set(first) != set(range(1, 13))
    reached = set()
    for seed in range(20):
        reached.update(take_samples_per_segment(df, ['segment'], 12, random_seed=seed)['Building'].to_list())
    assert len(reached) > 12


def test_segment_vars_are_characteristics_the_allocator_joins_on():
    segment_vars = read_sampler_config()['segment_vars']

    # Floor area bin flows downhill through the TSVs and is invisible to the allocator, so it
    # must not split segments
    assert 'Geometry Floor Area Bin' not in segment_vars
    assert set(segment_vars) == {
        'Federal Poverty Level',
        'Geometry Building Type RECS',
        'Vintage',
        'Heating Fuel',
        'Sampling Region',
    }


def test_one_config_value_sets_both_the_segment_count_and_the_take():
    num_samples_per_segment = read_sampler_config()['num_samples_per_segment']
    df = make_segment_df({'a': 100, 'b': 100})

    # The segment count arithmetic the sample command performs
    assert 550_000 // num_samples_per_segment * num_samples_per_segment <= 550_000

    taken = take_samples_per_segment(df, ['segment'], num_samples_per_segment)
    assert taken.height == 2 * num_samples_per_segment

def test_take_returns_every_column_including_the_segment_columns():
    df = make_segment_df({'a': 30, 'b': 5}).with_columns(pl.lit('x').alias('Other'))

    taken = take_samples_per_segment(df, ['segment'], 12)

    # pandas 3 `groupby(...).apply` drops the grouping columns; the take must not
    assert taken.columns == df.columns
    assert dict(taken.group_by('segment').len().iter_rows()) == {'a': 12, 'b': 5}
    # kept rows stay in their incoming order
    assert taken['Building'].to_list() == sorted(taken['Building'].to_list())


def write_chain_project(root: pathlib.Path) -> pathlib.Path:
    """Bedrooms -> Bedrooms Bin (deterministic) -> Occupants: the shape of Vintage -> Vintage ACS -> Income."""
    hc = root / 'housing_characteristics'
    hc.mkdir(parents=True)
    (hc / 'Bedrooms.tsv').write_text(
        'Option=1\tOption=2\tOption=3\tOption=4\tsampling_probability\n0.25\t0.25\t0.25\t0.25\t1\n')
    (hc / 'Bedrooms Bin.tsv').write_text(
        'Dependency=Bedrooms\tOption=Small\tOption=Large\tsampling_probability\n'
        '1\t1\t0\t0.25\n2\t1\t0\t0.25\n3\t0\t1\t0.25\n4\t0\t1\t0.25\n')
    (hc / 'Occupants.tsv').write_text(
        'Dependency=Bedrooms Bin\tOption=1\tOption=2\tOption=3\tsampling_probability\n'
        'Small\t0.6\t0.3\t0.1\t0.5\nLarge\t0.2\t0.4\t0.4\t0.5\n')
    return root


def run_sample_command(tmp_dir: str, num_datapoints: int = 24):
    from click.testing import CliRunner
    from sampler.run_sampler import cli
    project = write_chain_project(pathlib.Path(tmp_dir) / 'project')
    config = pathlib.Path(tmp_dir) / 'sampler_config.yaml'
    config.write_text(yaml.safe_dump({'segment_vars': ['Bedrooms', 'Occupants'],
                                      'segment_selection_sample_size': 5000,
                                      'num_samples_per_segment': 2}))
    output = pathlib.Path(tmp_dir) / 'buildstock.csv'
    result = CliRunner().invoke(cli, ['sample', '-p', str(project), '-n', str(num_datapoints),
                                      '-c', str(config), '-o', str(output)])
    return result, output


def test_sample_keeps_segments_and_their_deterministic_children_consistent():
    with tempfile.TemporaryDirectory() as tmp_dir:
        result, output = run_sample_command(tmp_dir)
        assert result.exit_code == 0, result.output
        df = pl.read_csv(output, infer_schema=False)
    expected_bin = df['Bedrooms'].replace_strict({'1': 'Small', '2': 'Small', '3': 'Large', '4': 'Large'})
    assert (df['Bedrooms Bin'] == expected_bin).all()
    assert df.group_by(['Bedrooms', 'Occupants']).len()['len'].max() <= 2


def test_sample_refuses_a_take_that_drops_the_segment_columns(monkeypatch):
    import sampler.run_sampler as rs
    original = rs.take_samples_per_segment

    def pandas3_take(df, segment_cols, n, random_seed=rs.RANDOM_SEED):
        # What the pandas `groupby(...).apply` take returned under pandas 3: no segment columns
        return original(df, segment_cols, n, random_seed).drop(segment_cols)

    monkeypatch.setattr(rs, 'take_samples_per_segment', pandas3_take)
    with tempfile.TemporaryDirectory() as tmp_dir:
        result, _ = run_sample_command(tmp_dir)
    assert result.exit_code != 0
    assert 'dropped the segment columns' in str(result.exception)


def test_find_impossible_samples_flags_a_stale_deterministic_child():
    from sampler.sampling_utils import find_impossible_samples
    with tempfile.TemporaryDirectory() as tmp_dir:
        project = write_chain_project(pathlib.Path(tmp_dir) / 'project')
        param2tsv = get_param2tsv(project)
        good = pd.DataFrame({'Bedrooms': ['1', '4'], 'Bedrooms Bin': ['Small', 'Large'], 'Occupants': ['1', '3']})
        assert find_impossible_samples(good, param2tsv) == {}
        stale = good.assign(Bedrooms=['4', '1'])  # re-drawn parent, child left behind
        bad = find_impossible_samples(stale, param2tsv)
        assert set(bad) == {'Bedrooms Bin'}
