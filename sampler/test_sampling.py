import pathlib
from buildstockbatch.sampler.residential_sampler.sampling_utils import read_char_tsv, get_param2tsv, get_issues, \
    get_samples, get_marginal_prob, get_tsv_issues, get_all_tsv_issues, get_tsv_max_sampling_errors, \
    get_all_tsv_max_errors

from buildstockbatch.sampler.residential_sampler.sampler import sample_param, sample_all
from collections import Counter
import pandas as pd
import tempfile
import math


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


def test_get_marginal_prob() -> None:
    assert get_marginal_prob(0.75, 2) == 0.5
    assert get_marginal_prob(0.25, 2) == 0.5
    assert get_marginal_prob(0.75, 4) == 0
    assert get_marginal_prob(0.75, 0) == 0
    assert get_marginal_prob(0.75, 1) == 0.75


def test_get_issues() -> None:
    issues = get_issues(["Yes"]*10, [1], ["Yes"])
    assert len(issues) == 0
    issues = get_issues(["Yes"], [0.5, 0.5], ["Yes", "No"])
    assert len(issues) == 0
    issues = get_issues(["No"], [0.5, 0.5], ["Yes", "No"])
    assert len(issues) == 0
    for sample, issue_count in [("A", 0), ("B", 0), ("C", 0), ("D", 1)]:
        issues = get_issues([sample], [0.3, 0.3, 0.3, 0.1], ["A", "B", "C", "D"])
        assert len(issues) == issue_count

    for samples, issue_count in [(["A", "B"], 0), (["A", "C"], 0), (["B", "C"], 0), (["A", "D"], 1)]:
        issues = get_issues(samples, [0.3, 0.3, 0.3, 0.1], ["A", "B", "C", "D"])
        assert len(issues) == issue_count

    issues = get_issues(["Yes", "No"], [1, 0], ["Yes", "No"])
    assert len(issues) == 1
    assert "marginal probability is 0" in issues[0]
    assert len(get_issues(["Yes", "No"], [0.75, 0.25], ["Yes", "No"])) == 0
    assert len(get_issues(["Yes", "Yes"], [0.75, 0.25], ["Yes", "No"])) == 0
    assert len(get_issues(["Yes", "Yes", "No"], [0.75, 0.25], ["Yes", "No"])) == 0

    issues = get_issues(["A", "A"], [0.2, 0.2], ["A", "B"])
    assert len(issues) == 1
    assert "marginal probability is 0 for A" in issues[0]

    issues = get_issues(["Yes", "Yes", "Yes"], [0.75, 0.25], ["Yes", "No"])
    assert len(issues) == 1
    assert "marginal probabilities are not equal" in issues[0]
    issues = get_issues(["No", "No", "No"], [0.75, 0.25], ["Yes", "No"])
    assert len(issues) == 2
    assert "Difference of more than 1 samples for option Yes" in issues
    assert "Difference of more than 1 samples for option No" in issues

    issues = get_issues(["A", "A", "A", "B", "C"], [0.2] * 5, ["A", "B", "C", "D", "E"])
    assert len(issues) > 1
    assert "Difference of more than 1 samples for option A" in issues
    assert "Differences in options don't sum to zero." in issues

    issues = get_issues(["A", "A", "B", "B", "B"], [0.2] * 5, ["A", "B", "C", "D", "E"])
    assert len(issues) > 1
    assert "Difference of more than 1 samples for option B" in issues
    assert "Differences in options don't sum to zero." in issues

    issues = get_issues(["A", "A", "B", "C", "D"], [0.2] * 5, ["A", "B", "C", "D", "E"])
    assert len(issues) == 1
    assert "marginal probability is 0" in issues[0]

    assert len(get_issues(["A", "E", "B", "C", "D"], [0.2] * 5, ["A", "B", "C", "D", "E"])) == 0

    # probabilities may not exactly sum to 1
    assert len(get_issues(["A", "E", "B", "C", "D"], [0.1] * 5, ["A", "B", "C", "D", "E"])) == 0


def test_get_tsv_issues():
    fan_tsv = pd.DataFrame({'Dependency=Bedrooms': [1, 2, 3, 4, 5],
                            'Option=None': [0.4] * 5,
                            'Option=Standard': [0.4] * 5,
                            'Option=Premium': [0.2] * 5})
    sample_df = pd.DataFrame({'Bedrooms': [1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
                              'Fan': ['None', 'Standard', 'None', 'Standard', 'None', 'Standard', 'None', 'Standard',
                                      'None', 'Standard']
                              })
    with tempfile.TemporaryDirectory() as tmp_dir:
        tsv_file = tmp_dir + "/Fan.tsv"
        fan_tsv.to_csv(tsv_file, sep='\t', index=False)
        tsv_tuple = read_char_tsv(tsv_file)
        issues = get_tsv_issues(param='Fan', tsv_tuple=tsv_tuple, sample_df=sample_df)
        assert len(issues) == 0

    fan_tsv = pd.DataFrame({'Option=None': [0.4],
                            'Option=Standard': [0.4],
                            'Option=Premium': [0.2]})
    sample_df = pd.DataFrame({'Bedrooms': [1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
                              'Fan': ['None', 'Standard', 'None', 'Standard', 'None', 'Standard', 'None', 'Standard',
                                      'None', 'Standard']
                              })
    with tempfile.TemporaryDirectory() as tmp_dir:
        tsv_file = tmp_dir + "/Fan.tsv"
        fan_tsv.to_csv(tsv_file, sep='\t', index=False)
        tsv_tuple = read_char_tsv(tsv_file)
        issues = get_tsv_issues(param='Fan', tsv_tuple=tsv_tuple, sample_df=sample_df)
        assert len(issues) > 0
        assert "Differences in options don't sum to zero." in issues
        assert "Difference of more than 1 samples for option Premium" in issues

    fan_tsv = pd.DataFrame({'Dependency=Bedrooms': [1, 2, 3, 4, 5],
                            'Option=None': [0.4] * 5,
                            'Option=Standard': [0.4] * 5,
                            'Option=Premium': [0.2] * 5})
    sample_df = pd.DataFrame({'Bedrooms': [1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
                              'Fan': ['None', 'Standard', 'None', 'Standard', 'Premium', 'Standard', 'None', 'Standard',
                                      'None', 'Premium']
                              })
    with tempfile.TemporaryDirectory() as tmp_dir:
        tsv_file = tmp_dir + "/Fan.tsv"
        fan_tsv.to_csv(tsv_file, sep='\t', index=False)
        tsv_tuple = read_char_tsv(tsv_file)
        issues = get_tsv_issues(param='Fan', tsv_tuple=tsv_tuple, sample_df=sample_df)
        assert len(issues) == 2
        assert "Premium has one sample more" in issues[0]
        assert "Premium has one sample more" in issues[1]


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


def test_get_all_tsv_issues() -> None:
    project_dir = pathlib.Path(__file__).parent / 'project_sampling_test'
    sample_df = pd.DataFrame({'Bedrooms': ['1', '1', '2', '2', '3', '3', '4', '4', '5', '5'],
                              'Ceiling Fan': ['None', 'Standard', 'None', 'Standard', 'None', 'Standard', 'None',
                                              'Standard', 'None', 'Standard'],
                              'Uses AC': ['Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'No']
                              })
    issues_dict = get_all_tsv_issues(sample_df=sample_df, project_dir=project_dir)
    assert len(issues_dict) == 3
    for param, issues in issues_dict.items():
        assert issues == []

    sample_df = pd.DataFrame({'Bedrooms': ['1', '1', '2', '2', '3', '3', '4', '4', '5', '5'],
                              'Ceiling Fan': ['None', 'Standard', 'None', 'Standard', 'None', 'Standard', 'None',
                                              'Standard', 'None', 'Standard'],
                              'Uses AC': ['No', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'No']
                              })  # this should pass too
    issues_dict = get_all_tsv_issues(sample_df=sample_df, project_dir=project_dir)
    assert len(issues_dict) == 3
    for param, issues in issues_dict.items():
        assert issues == []


def test_get_all_tsv_issues2() -> None:
    project_dir = pathlib.Path(__file__).parent / 'project_sampling_test2'
    sample_df = pd.DataFrame({'Bedrooms': ['1', '1', '2', '2', '3', '3', '4', '4', '5', '5'],
                              'Ceiling Fan': ['Premium', 'None', 'Standard', 'None', 'Premium', 'Premium', 'Standard',
                                              'None', 'Standard', 'None'],
                              'Uses AC': ['No', 'Yes', 'Yes', 'Yes', 'No', 'No', 'Yes', 'Yes', 'No', 'Yes']
                              })
    issues_dict = get_all_tsv_issues(sample_df=sample_df, project_dir=project_dir)
    assert len(issues_dict) == 3
    for param, issues in issues_dict.items():
        assert issues == []

    tsv_file = pathlib.Path(__file__).parent / 'project_sampling_test2' / 'housing_characteristics' / 'Ceiling Fan.tsv'
    ac_file = pathlib.Path(__file__).parent / 'project_sampling_test2' / 'housing_characteristics' / 'Uses AC.tsv'
    bedroom_file = pathlib.Path(__file__).parent / 'project_sampling_test2' / 'housing_characteristics' / 'Bedrooms.tsv'
    ceiling_fan_tuple = read_char_tsv(tsv_file)
    ac_tuple = read_char_tsv(ac_file)
    bedroom_tuple = read_char_tsv(bedroom_file)

    # Demonstrate that downsampling by taking a random slice can fail the verification

    # if the slice happen to have same distribution as the whole df, it will pass verification
    sub_df = sample_df[sample_df['Bedrooms'] == '5']
    tsv_issues = get_tsv_issues(param='Ceiling Fan', tsv_tuple=ceiling_fan_tuple, sample_df=sub_df)
    assert len(tsv_issues) == 0

    # but if the slice has different distribution, it will fail the verification for the characteristic
    sub_df = sample_df[sample_df['Bedrooms'] == '3']
    """
      Bedrooms      Ceiling Fan     Uses AC
            3           Premium          No
            3           Premium          No
    """
    tsv_issues = get_tsv_issues(param='Ceiling Fan', tsv_tuple=ceiling_fan_tuple, sample_df=sub_df)
    assert len(tsv_issues) > 0
    assert "Difference of more than 1 samples for option Premium" in tsv_issues[0]
    tsv_issues = get_tsv_issues(param='Bedrooms', tsv_tuple=bedroom_tuple, sample_df=sub_df)
    assert len(tsv_issues) > 0
    assert "Difference of more than 1 samples for option 3" in tsv_issues[0]
    # it should still pass for the other characteristic for which the slice has the correct distribution
    tsv_issues = get_tsv_issues(param='Uses AC', tsv_tuple=ac_tuple, sample_df=sub_df)
    assert len(tsv_issues) == 0


def test_get_tsv_errors() -> None:
    project_dir = pathlib.Path(__file__).parent / 'project_sampling_test'
    sample_df = pd.DataFrame({'Bedrooms': ['1', '1', '2', '2', '3', '3', '4', '4', '5', '5'],
                              'Ceiling Fan': ['None', 'Standard', 'None', 'Standard', 'None', 'Standard', 'None',
                                              'Standard', 'None', 'Standard'],
                              'Uses AC': ['Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'No']
                              })
    nsamples = len(sample_df)
    tsv_tuple = read_char_tsv(project_dir / 'housing_characteristics' / 'Bedrooms.tsv')
    error_dict = get_tsv_max_sampling_errors(param='Bedrooms', tsv_tuple=tsv_tuple, sample_df=sample_df)
    assert error_dict['max_group_error'] == 0
    assert error_dict['groups_error_l2norm'] == 0
    assert error_dict['max_group_error_group'] == ()
    assert error_dict['max_option_error'] == 0
    assert error_dict['options_error_l2norm'] == 0

    tsv_tuple = read_char_tsv(project_dir / 'housing_characteristics' / 'Ceiling Fan.tsv')
    error_dict = get_tsv_max_sampling_errors(param='Ceiling Fan', tsv_tuple=tsv_tuple, sample_df=sample_df)
    assert error_dict['max_group_error'] == 0
    assert error_dict['groups_error_l2norm'] == 0
    assert error_dict['max_group_error_group'] in [(str(i),) for i in range(1, 6)]
    assert math.isclose(error_dict['max_option_error'], 2.0 / nsamples)
    assert error_dict['max_option_error_option'] == 'Premium'
    assert math.isclose(error_dict['options_error_l2norm'], math.sqrt(0.1**2 + 0.1**2 + 0.2**2) / math.sqrt(3))

    tsv_tuple = read_char_tsv(project_dir / 'housing_characteristics' / 'Uses AC.tsv')
    error_dict = get_tsv_max_sampling_errors(param='Uses AC', tsv_tuple=tsv_tuple, sample_df=sample_df)
    assert math.isclose(error_dict['max_group_error'], 2.0 / nsamples)
    assert math.isclose(error_dict['groups_error_l2norm'], math.sqrt(0.1**2 + 0.1**2 + 0.2**2) / math.sqrt(3))
    assert error_dict['max_group_error_group'] == ('Premium',)
    assert error_dict['max_option_error_option'] in ('No', 'Yes')
    assert math.isclose(error_dict['options_error_l2norm'], math.sqrt(0.2**2 + 0.2**2) / math.sqrt(2))


def test_get_all_tsv_errors() -> None:
    project_dir = pathlib.Path(__file__).parent / 'project_sampling_test'
    sample_df = pd.DataFrame({'Bedrooms': [1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
                              'Ceiling Fan': ['None', 'Standard', 'None', 'Standard', 'None', 'Standard', 'None',
                                              'Standard', 'None', 'Standard'],
                              'Uses AC': ['Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'No']
                              })
    nsamples = len(sample_df)
    error_df = get_all_tsv_max_errors(sample_df=sample_df, project_dir=project_dir)
    assert len(error_df) == 3
    assert error_df.loc['Bedrooms'].max_group_error == 0
    assert error_df.loc['Bedrooms'].groups_error_l2norm == 0
    assert error_df.loc['Bedrooms'].max_group_error_group == ()
    assert error_df.loc['Bedrooms'].max_option_error == 0
    assert error_df.loc['Bedrooms'].options_error_l2norm == 0
    edf = error_df.loc['Ceiling Fan']
    assert math.isclose(edf.max_group_error, 0)
    assert math.isclose(edf.groups_error_l2norm, 0)
    assert edf.max_group_error_group in [(str(i),) for i in range(1, 6)]
    assert math.isclose(edf.max_option_error, 2.0 / nsamples)
    assert edf.max_option_error_option == 'Premium'
    assert math.isclose(edf.options_error_l2norm, math.sqrt(0.1**2 + 0.1**2 + 0.2**2) / math.sqrt(3))
    edf = error_df.loc['Uses AC']
    assert math.isclose(edf.max_group_error, 2 / nsamples)
    assert math.isclose(edf.groups_error_l2norm, math.sqrt(0.1**2 + 0.1**2 + 0.2**2) / math.sqrt(3))
    assert edf.max_group_error_group == ('Premium',)
    assert edf.max_option_error_option in ['No', 'Yes']
    assert math.isclose(edf.options_error_l2norm, math.sqrt(0.2**2 + 0.2**2) / math.sqrt(2))
