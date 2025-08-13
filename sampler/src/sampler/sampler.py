import pandas as pd
import networkx as nx
import time
import itertools as it
import multiprocessing
import click
import pathlib
from .sampling_utils import get_param2tsv, get_samples, TSVTuple, get_all_tsv_issues, get_all_tsv_max_errors
from .sampling_utils import get_error_details
from .utils import log_error_details, read_csv
import random
random.seed(42)


def get_param_graph(param2dep: dict[str, list[str]]) -> nx.DiGraph:
    param2dep_graph = nx.DiGraph()
    for param, dep_list in param2dep.items():
        param2dep_graph.add_node(param)
        for dep in dep_list:
            param2dep_graph.add_edge(dep, param)
    return param2dep_graph


def get_topological_param_list(param2dep: dict[str, list[str]]) -> list[str]:
    param2dep_graph = get_param_graph(param2dep)
    topo_params = list(nx.topological_sort(param2dep_graph))
    return topo_params


def get_topological_generations(param2dep: dict[str, list[str]], segment_vars: set[str] | None = None) -> list[tuple[int, list[str]]]:
    param2dep_graph = get_param_graph(param2dep)
    if segment_vars:
        ancestors = set()
        for tsv_name in segment_vars:
            ancestors.update(nx.ancestors(param2dep_graph, tsv_name))
        ancestors.update(segment_vars)
        param2dep_graph = param2dep_graph.subgraph(ancestors)  # type: ignore
    return list(sorted(enumerate(nx.topological_generations(param2dep_graph))))  # type: ignore


def sample_param(param_tuple: TSVTuple, sample_df: pd.DataFrame, param: str, num_samples: int,
                 random_seed: int) -> list[str]:
    print(f"Sampling {param} with {num_samples} samples")
    try:
        random.seed(random_seed)
        start_time = time.time()
        group2values, dep_cols, opt_cols = param_tuple
        if not dep_cols:
            probs = group2values[()]
            samples = get_samples(probs, opt_cols, num_samples)
        else:
            grouped_df = sample_df.groupby(dep_cols, sort=False)
            flat_samples = [''] * num_samples
            for group_key, indexes in grouped_df.groups.items():
                group_key = group_key if isinstance(group_key, tuple) else (str(group_key),)
                probs = group2values[group_key]
                samples = get_samples(probs, opt_cols, len(indexes))
                for index, sample in zip(indexes, samples):
                    flat_samples[index] = sample
            return flat_samples
    except Exception:
        print(f"Prininting error for {param}")
        text = "\n" + "#" * 20 + "\n"
        text += get_error_details()
        print(text)
        raise
    print(f"Returning samples for {param} in {time.time() - start_time:.2f}s")
    return samples


def sample_all(project_path, num_samples, segment_vars: set[str] | None = None, initial_samples_df: pd.DataFrame | None = None) -> pd.DataFrame:
    param2tsv = get_param2tsv(project_path)
    param2dep = {param: tsv_tuple[1] for (param, tsv_tuple) in param2tsv.items()}

    if initial_samples_df is not None:
        sample_df = initial_samples_df
        already_available_columns = set(sample_df.columns.values)
        assert num_samples == len(sample_df)
    else:
        sample_df = pd.DataFrame()
        sample_df.loc[:, "Building"] = list(range(1, num_samples+1))
        already_available_columns = set()

    s_time = time.time()
    with multiprocessing.Pool(processes=max(multiprocessing.cpu_count() - 2, 1)) as pool:
        for level, params in get_topological_generations(param2dep, segment_vars):
            print(f"Sampling {len(params)} params in a batch at level {level}")
            results = []
            already_sampled = already_available_columns.intersection(params)
            remaining_params = set(params) - already_sampled
            if already_sampled:
                print(f"Skipping {len(already_sampled)} params as they are already available")
            if not remaining_params:
                continue
            for param in remaining_params:
                _, dep_cols, _ = param2tsv[param]
                seed = random.randint(0, 10**10)
                res = pool.apply_async(sample_param,
                                       (param2tsv[param], sample_df[dep_cols], param, num_samples, seed))
                results.append(res)
            st = time.time()
            samples_dict = {param: res_val.get() for param, res_val in zip(remaining_params, results)}
            print(f"Got results for {len(samples_dict)} params in {time.time()-st:.2f}s")
            assert len(samples_dict) == len(remaining_params)
            new_df = pd.DataFrame(samples_dict)
            sample_df = pd.concat([sample_df, new_df], axis=1)
    print(f"Sampled in {time.time()-s_time:.2f} seconds")
    print(f"Done sampling {len(param2tsv)} TSVs with {num_samples} samples.")
    return sample_df


@click.group()
def cli():
    """Perform sampling or verify existing samples (in buildstock.csv).
       Type `resstock_sampler sample --help` or `resstock_sampler verify --help` to know more.
    """
    pass


@cli.command()
@click.option("-p", "--project", type=str, required=True,
              help="The path to the project (most have housing_characteristics folder inside)")
@click.option("-n", "--num_datapoints", type=int, required=True,
              help="The number of datapoints to sample.")
@click.option("-o", "--output", type=str, required=True,
              help="The output filename for samples.")
def sample(project: str, num_datapoints: int, output: str) -> None:
    """Performs sampling for project and writes output parquet file.
    """
    segment_vars = ["Federal Poverty Level", "Geometry Floor Area Bin", "Geometry Building Type RECS", "Vintage", "Heating Fuel", "Sampling Region"]
    # initial_samples_df = read_csv('/Users/radhikar/Documents/buildstock2025/geographic sampling/starter_samples.csv')
    initial_samples_df = None
    start_time = time.time()
    print(project, num_datapoints, output)
    sample_df = sample_all(pathlib.Path(project), num_datapoints, initial_samples_df=initial_samples_df)
    click.echo("Writing Parquet")
    sample_df.to_parquet(output)
    click.echo(f"Completed sampling in {time.time() - start_time:.2f} seconds")


@cli.command()
@click.argument("buildstock_file", type=str, required=True)
@click.option("-p", "--project", type=str, required=True,
              help="The path to the project (most have housing_characteristics folder inside)")
@click.option("-o", "--output", type=str, default='errors.csv',
              help="The output filename for error report.")
def verify(buildstock_file: str, project: str, output: str):
    """
       \b
       Checks the buildstock.csv file (BUILDSTOCK_FILE) for correctness. BUILDSTOCK_FILE is considered correct if
       the probability distribution in project TSVs can result in the BUILDSTOCK_FILE using quota sampling.

       \b
       In addition to correctness verification, it also calculates the sample probability distribution error for the
       options in each TSVs between the BUILDSTOCK_FILE and what one would expect based on the probabilities. It also
       calculates sampling errors for each group in the TSV. An example is provided below to explain the error
       calculation further.
       Consider a project with three TSVs.
       Bedrooms.tsv
       ----------
       Option=1    Option=2    Option=3    Option=4    Option=5    sampling_probability
            0.2         0.2         0.2         0.2         0.2                     1.0
       \b
       Fan.tsv
       ----------
       Dependency=Bedrooms    Option=None    Option=Standard    Option=Premium    sampling_probability
                        1            0.35              0.35                0.3                     0.2
                        2            0.35              0.35                0.3                     0.2
                        3            0.35              0.35                0.3                     0.2
                        4            0.35              0.35                0.3                     0.2
                        5            0.35              0.35                0.3                     0.2
       \b
       AC.tsv
       ----------
       Dependency=Fan       Option=Yes    Option=No    sampling_probability
                    None           0.9          0.1                    0.35
                Standard           0.8          0.2                    0.35
                 Premium           0.1          0.9                    0.3
       Quota sampling in the above project for 10 samples can generate a buildstock.csv that looks like this:
       buildstock.csv
       -------------
       Building  Bedrooms         Fan            AC
              *         1         None          Yes
              *         1         Standard      Yes
              *         2         None          Yes
              *         2         Standard      Yes
              *         3         None          Yes
              *         3         Standard      Yes
              *         4         None          Yes
              *         4         Standard      Yes
              *         5         None          Yes
              *         5         Standard       No
       \b
       For nsamples=10, the error calculation for each of the TSV will be as follows.
       For Bedrooms.tsv, distribution of various bedrooms is 0.2 in the buildstock.csv which exactly matches with the
       distribution in the TSV. Hences, max_option_error = total_option_error = 0.
       Since there are no dependencies, the max_group_error and total_group_error is also 0.
       \b
       For Fan.tsv, we expect the sample distribution for None, Standard and Premium to be 0.35, 0.35 and 0.3.
       The actual distribution is 0.5, 0.5 and 0.0. This gives absolute distribution errors as 0.15, 0.15 and 0.3.
       Hence, the max_option_error is 0.3 and total_option_error is 0.6
       There are 5 dependency groups [(1,), (2,), (3,), (4,), (5,)] in Fan.tsv with expected sample distribution of
       [0.2, 0.2, 0.2, 0.2, 0.2]. The actual probability distribution for these groups are also the same, both the
       max_group_error and total_group_error is 0.
       \b
       For AC.tsv, expect the sample distribution for Yes and No to be 0.625 (0.9 * 0.35 + 0.8 * 0.35 + 0.1 * 0.3) and
       0.375. The actual sample distribution we have for Yes and No is 0.9 and 0.1. This gives absolute distribution
       errors as 0.275 and 0.275. Hence, the max_option_error = 0.275 and total_option_error is 0.55.
       There are 3 dependency groups [(None,), (Standard,), (Premium,)] in AC.tsv with expected sample distribution of
       0.35, 0.35 and 0.3. The actual sample distribution we have for [(None,), (Standard,), (Premium,)] is 0.5, 0.5, 0.
       This gives absolute distribution error for group as 0.15, 0.15 and 0.3. Hence, max_group_error is 0.3 and
       total_group_eror is 0.6
       \b
       ----------------------
       \b
       Caution about downsampling through slicing
       \b
       A downsampled buildstock.csv created by selecting a subset of rows from the original buildstock.csv file
       WILL NOT pass the verification. This is because only the full buildstock.csv file is expected to have the
       distribution of various characteristics to closely follow the probabilities in the TSV. A random slice of the
       full buildstock.csv file can have very skewed distribution of some characteristics, and it will not pass the
       verification because the skewed distribution cannot be justified by the probabilities in the TSV.

       \b
       Consider this slightly modified example (in this case Fan.tsv has no dependency on Bedrooms.tsv)

       \b
       Bedrooms.tsv
       ----------
       Option=1    Option=2    Option=3    Option=4    Option=5    sampling_probability
            0.2         0.2         0.2         0.2         0.2                     1.0
       \b
       Fan.tsv
       ----------
        Option=None    Option=Standard    Option=Premium    sampling_probability
               0.35              0.35                0.3                     0.2
       \b
       AC.tsv
       ----------
       Dependency=Fan       Option=Yes    Option=No    sampling_probability
                 None              0.9          0.1                    0.35
             Standard              0.8          0.2                    0.35
              Premium              0.1          0.9                    0.30
       \b
       Quota sampling in the above project for 10 samples can generate a buildstock.csv that looks like this:
       buildstock.csv
       -------------
       Building  Bedrooms         Fan           AC
              *         1         Premium       No
              *         1         None          Yes
              *         2         Standard      Yes
              *         2         None          Yes
              *         3         Premium       No
              *         3         Premium       No
              *         4         Standard      Yes
              *         4         None          Yes
              *         5         Standard      No
              *         5         None          Yes
       \b
       If we downsample this buildstock.csv to 2 samples for only Bedrooms=3, we get the following buildstock.csv
       buildstock.csv
       -------------
       Building  Bedrooms         Fan           AC
              *         3         Premium       No
              *         3         Premium       No
       \b
       This downsampled buildstock.csv will not pass the verification for Fan.tsv and Bedrooms.tsv because the
       samples are very skewed from the expected distribution in the TSV file. Even if we update the Bedrooms.tsv to
       only have Bedrooms=3 as shown below, the downsampled buildstock.csv will still not pass the verification
       for Fan.tsv.
       \b
       In order to create a downsampled buildstock.csv file that passes the verification, we need to rerun the sampler
       with correct number of samples and updated TSV required for the downsampled buildstock.csv file. For example,
       we can update the Bedrooms.tsv to only have Bedrooms=3 as follows:
       Bedrooms.tsv
       ----------
       Option=1    Option=2    Option=3    Option=4    Option=5    sampling_probability
            0.0         0.0         1.0         0.0         0.0                     1.0
       \b
       and rerun the sampler with nsamples=2. This will give us
       a buildstock.csv file that looks like this:
       buildstock.csv
       -------------
       Building  Bedrooms         Fan           AC
              *         3         None          Yes
              *         3         Standard      Yes
       \b
       This buildstock.csv file will pass the verification for all TSVs.
       \b
       Please note that not passing the verification does not mean that the buildstock.csv file is necessarily
       wrong. It just means that the buildstock.csv file has a skewed distribution from what one would expect based
       on the probabilities in the TSVs. The skew will be larger for smaller slices. For example, if we downsample
       the buildstock.csv file to 100 samples, the skew will be much smaller than if we downsample to 2 samples.
    """
    print("Verifying buildstock.csv file.")
    buildstock_df = read_csv(buildstock_file, dtype=str)
    buildstock_df = buildstock_df.astype(str)
    issues_dict = get_all_tsv_issues(buildstock_df, pathlib.Path(project))
    issues_found = False
    for param, issues in issues_dict.items():
        if issues:
            click.echo(click.style(f"Following issues found for {param}", fg='red'))
            click.echo(click.style('\n'.join(issues), fg='red'))
            issues_found = True
    if not issues_found:
        click.echo(click.style("Buildstock.csv is correct.", fg='green'))
    click.echo("Now calculating max sampling error.")
    error_df = get_all_tsv_max_errors(sample_df=buildstock_df, project_dir=pathlib.Path(project))
    error_df = error_df.sort_values(by=['options_error_l2norm'], key=lambda x: abs(x), ascending=False)
    click.echo("Top 10 TSVs with maximum option sampling errors")
    click.echo(error_df.head(10))
    error_df.to_csv(output)
    error_df = error_df.sort_values(by=['groups_error_l2norm'], key=lambda x: abs(x), ascending=False)
    click.echo("Top 10 TSVs with maximum group sampling errors")
    click.echo(error_df.head(10))


@log_error_details("sampler_error.txt")
def main() -> None:
    cli()


if __name__ == "__main__":
    main()