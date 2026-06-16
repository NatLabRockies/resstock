import pandas as pd
import networkx as nx
import time
import multiprocessing
import click
import pathlib
import yaml
import polars as pl
import os, sys
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from sampler.sampling_utils import get_param2tsv, get_samples, TSVTuple
from sampler.utils import log_error_details, get_error_details
import random

# Set seeds for reproducibility
RANDOM_SEED = 42  # Use a fixed seed
random.seed(RANDOM_SEED)


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
        print(f"Trimmed the network to {len(param2dep_graph.nodes)} nodes")
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


def sample_param_wrapper(args):
    """Wrapper function to unpack arguments for pool.map()"""
    param, param_tsv_data, sample_data, num_samples, seed = args
    result = sample_param(param_tsv_data, sample_data, param, num_samples, seed)
    return param, result


def sample_all(project_path, num_samples, *, segment_vars: set[str] | None = None, initial_samples_df: pd.DataFrame | None = None) -> pd.DataFrame:
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
    tsv_count = 0

    with multiprocessing.Pool(processes=max(multiprocessing.cpu_count() - 2, 1)) as pool:
        for level, params in get_topological_generations(param2dep, segment_vars):
            print(f"Sampling {len(params)} params in a batch at level {level}")

            # Ensure deterministic ordering
            already_sampled = sorted(already_available_columns.intersection(params))
            remaining_params = sorted(set(params) - set(already_sampled))

            if already_sampled:
                print(f"Skipping {len(already_sampled)} params as they are already available")
            if not remaining_params:
                continue

            # Prepare arguments for pool.map()
            task_args = []
            for i, param in enumerate(remaining_params):
                _, dep_cols, _ = param2tsv[param]
                seed = RANDOM_SEED + i
                task_args.append((param, param2tsv[param], sample_df[dep_cols], num_samples, seed))

            st = time.time()
            results = pool.map(sample_param_wrapper, task_args)
            samples_dict = {param: result for param, result in results}
            print(f"Got results for {len(samples_dict)} params in {time.time()-st:.2f}s")

            assert len(samples_dict) == len(remaining_params)
            tsv_count += len(samples_dict)

            new_df = pd.DataFrame(samples_dict)
            sample_df = pd.concat([sample_df, new_df], axis=1)

    print(f"Sampled in {time.time()-s_time:.2f} seconds")
    print(f"Done sampling {tsv_count} TSVs with {num_samples} samples.")
    return sample_df


@click.group()
def cli():
    """Perform sampling or verify existing samples (in buildstock.csv).
       Type `resstock_sampler sample --help` or `resstock_sampler verify --help` to know more.
    """
    pass


@cli.command()
@click.option("-p", "--project", type=str, required=True,
              help="The path to the project (most have housing_characteristics folder inside).")
@click.option("-n", "--num-datapoints", type=int, required=True,
              help="The number of datapoints to sample.")
@click.option("-c", "--config", type=str, required=False,
              help="The path to the config.")
@click.option("-o", "--output", type=str, required=True,
              help="The output filename for samples.")
def sample(project: str, num_datapoints: int, config: str, output: str) -> None:
    """Performs sampling for project and writes output parquet file.
    """
    # Load config file
    if config:
        # from argument passed in
        config_path = pathlib.Path(config)
    else:
        # from same directory as this script
        config_path = pathlib.Path(__file__).parent / "sampler_config.yaml"
    segment_vars = None
    config = {}
    if config_path.exists():
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
    segment_vars = set(config.get('segment_vars', []))
    initial_sample_size = config.get('segment_selection_sample_size', 10000000)
    initial_samples_df = None
    init_start_time = time.time()
    print(project, num_datapoints, output, segment_vars)
    print(f"Performing initial sampling with {initial_sample_size} samples to pick the segments")
    initial_samples_df = pl.from_pandas(sample_all(pathlib.Path(project), initial_sample_size, segment_vars=segment_vars))
    print(f"Initial sampling completed in {time.time() - init_start_time:.2f} seconds. Sample size: {initial_samples_df.shape}")
    initial_samples_df = initial_samples_df.drop("Building")
    num_samples_per_segment = config.get('num_samples_per_segment', 12)
    num_segments = num_datapoints // num_samples_per_segment
    top_segments = initial_samples_df.group_by(segment_vars).agg(pl.len().alias("count")).sort("count", descending=True).limit(num_segments)
    new_df = initial_samples_df.join(top_segments, on=segment_vars, validate="m:1", how="left")
    valid_df = new_df.filter(~pl.col('count').is_null())
    valid_df = valid_df.drop("count")
    limited_df = (
        valid_df
        .group_by(segment_vars, maintain_order=True)   # keep incoming row-order inside groups
        .head(num_samples_per_segment)
    )
    new_total = limited_df.shape[0]
    if new_total < num_datapoints:
        print(f"Will be sampling {new_total} samples instead of {num_datapoints} due to rounding")
    limited_df = limited_df.with_row_index("Building", offset=1)
    initial_samples_df = limited_df.to_pandas()
    final_start_time = time.time()
    print(f"Performing final sampling with {num_segments} segments")
    sample_df = sample_all(pathlib.Path(project), new_total, initial_samples_df=initial_samples_df)
    print(f"Final sampling completed in {time.time() - final_start_time:.2f} seconds")
    click.echo("Writing Buildstock CSV")
    if not pathlib.Path(output).is_absolute():
        output = str((pathlib.Path(__file__).resolve().parent / ".." / ".." / ".."/ "resources" / output).resolve())
    pl.from_pandas(sample_df).write_csv(output)
    click.echo(f"Completed sampling in {(time.time() - init_start_time) / 60:.2f} minutes")


@log_error_details("sampler_error.txt")
def main() -> None:
    cli()


if __name__ == "__main__":
    main()
