import pathlib
from sampler.sampling_utils import read_char_tsv, get_param2tsv, get_samples
from sampler.sampler import sample_param, sample_all
from collections import Counter
import pandas as pd
import tempfile


def test_get_samples() -> None:
    samples = get_samples(probs=[1], options=["Yes"], num_samples=10)
    assert samples == ["Yes"]*10
    samples = get_samples(probs=[0.5, 0.5], options=["Yes", "No"], num_samples=4)
    assert sorted(samples) == ['No', 'No', 'Yes', 'Yes']

    samples = get_samples(probs=[0.5, 0.5], options=["Yes", "No"], num_samples=1)
    assert samples in [['No'], ['Yes']]

    samples = get_samples(probs=[0.2]*5, options=["A", "B", "C", "D", "E"], num_samples=2)
    assert sorted(samples) == ['A', 'B']
    # probabilities may not exactly sum to 1
    samples = get_samples(probs=[0.49, 0.49], options=["Yes", "No"], num_samples=4)
    assert sorted(samples) == ['No', 'No', 'Yes', 'Yes']
    samples = get_samples(probs=[0.5, 0.5], options=["Yes", "No"], num_samples=3)
    assert sorted(samples) in [['No', 'No', 'Yes'], ['No', 'Yes', 'Yes']]
    samples = get_samples(probs=[0.75, 0.25], options=["Yes", "No"], num_samples=2)
    assert sorted(samples) in [['Yes', 'Yes'], ['No', 'Yes']]
    samples = get_samples(probs=[0.6, 0.15, 0.15, 0.10], options=["A", "B", "C", "D"], num_samples=2)
    assert sorted(samples) == ['A', 'A']
    samples = get_samples(probs=[0.6, 0.15, 0.15, 0.10], options=["A", "B", "C", "D"], num_samples=198)
    assert Counter(samples) in [Counter({'A': 119, 'B': 30, 'C': 29, 'D': 20}),
                                Counter({'A': 119, 'B': 29, 'C': 30, 'D': 20})]

def test_sample_param():
    bedrooms_tsv = pd.DataFrame({'Option=1': [0.2], 'Option=2': [0.2], 'Option=3': [0.2], 'Option=4': [0.2],
                                 'Option=5': [0.2]})
    fan_tsv = pd.DataFrame({'Dependency=Bedrooms': [1, 2, 3, 4, 5],
                            'Option=None': [0.4] * 5,
                            'Option=Standard': [0.4] * 5,
                            'Option=Premium': [0.2] * 5})
    sample_df = pd.DataFrame({'Building': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]})
    with tempfile.TemporaryDirectory() as tmp_dir:
        tsv_file = tmp_dir + "/Bedrooms.tsv"
        bedrooms_tsv.to_csv(tsv_file, sep='\t', index=False)
        tsv_tuple = read_char_tsv(tsv_file)
        samples = sample_param(param_tuple=tsv_tuple, sample_df=sample_df, param='Bedrooms', num_samples=10)
        assert len(samples) == 10
        assert sorted(samples) == ['1', '1', '2', '2', '3', '3', '4', '4', '5', '5']
        sample_df['Bedrooms'] = samples
        assert get_tsv_issues('Bedrooms', tsv_tuple, sample_df) == []
        tsv_file = tmp_dir + "/Ceiling Fan.tsv"
        fan_tsv.to_csv(tsv_file, sep='\t', index=False)
        tsv_tuple = read_char_tsv(tsv_file)
        samples = sample_param(param_tuple=tsv_tuple, sample_df=sample_df, param='Bedrooms', num_samples=10)
        assert len(samples) == 10
        assert sorted(samples) == ['None'] * 5 + ['Standard'] * 5
        sample_df['Fan'] = samples
        assert get_tsv_issues('Fan', tsv_tuple, sample_df) == []


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
    assert group2probs[()] == [0.2] * 5 + [1.0]
    group2probs, dep_cols, opt_cols = param2tsv['Ceiling Fan']
    assert dep_cols == ['Bedrooms']
    assert opt_cols == ['None', 'Standard', 'Premium']
    assert len(group2probs) == 5
    for group in ['1', '2', '3', '4', '5']:
        assert group2probs[(group,)] == [0.4, 0.4, 0.2, 0.2]
    group2probs, dep_cols, opt_cols = param2tsv['Uses AC']
    assert dep_cols == ['Ceiling Fan']
    assert opt_cols == ['Yes', 'No']
    assert len(group2probs) == 3


def test_sample_all():
    project_dir = pathlib.Path(__file__).parent / 'project_sampling_test'
    sample_df = sample_all(project_dir, 10)
    assert len(sample_df) == 10
    tsv_tuple = read_char_tsv(project_dir / 'housing_characteristics' / 'Bedrooms.tsv')
    assert get_tsv_issues(param='Bedrooms', tsv_tuple=tsv_tuple, sample_df=sample_df) == []
    tsv_tuple = read_char_tsv(project_dir / 'housing_characteristics' / 'Ceiling Fan.tsv')
    assert get_tsv_issues(param='Ceiling Fan', tsv_tuple=tsv_tuple, sample_df=sample_df) == []
