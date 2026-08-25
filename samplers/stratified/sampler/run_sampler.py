import pandas as pd
import networkx as nx
import numpy as np
import time
import multiprocessing
import click
import pathlib
import yaml
import polars as pl
import os, sys
import hashlib
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from sampler.sampling_utils import get_param2tsv, get_samples, TSVTuple
from sampler.utils import log_error_details, get_error_details
import random

# Seeds every draw the sampler makes: the per-TSV seeds handed to the worker pool and the
# per-segment take that trims each segment to num_samples_per_segment buildings.
RANDOM_SEED = 42

# Buildings kept per segment when sampler_config.yaml does not say
DEFAULT_NUM_SAMPLES_PER_SEGMENT = 12

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
            by = dep_cols[0] if len(dep_cols) == 1 else dep_cols
            grouped_df = sample_df.groupby(by, sort=False)
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
            for param in remaining_params:
                _, dep_cols, _ = param2tsv[param]
                param_seed = int.from_bytes(hashlib.blake2b(param.encode(), digest_size=4).digest(), "big")
                seed = RANDOM_SEED + param_seed
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


def add_coverage_floor_segments(pilot_df: pl.DataFrame, segment_counts: pl.DataFrame,
                                top_segments: pl.DataFrame, segment_cols: list[str],
                                coverage_floor_vars: list[str]) -> pl.DataFrame:
    """Add the segments needed to leave every pilot-reached floor cell with a selected segment.

    The rank cut keeps the most populous `num_segments` segments and is all-or-nothing: a floor
    cell whose segments all sit below the cut contributes no buildings at all, and the allocator's
    fallback ladder releases only vintage and federal poverty level, so no other building can
    stand in for it. This adds back one segment per floor cell the cut missed — the most populous
    of the segments the pilot placed in that cell, with the same segment-value tie-break the cut
    itself uses — so the selection reaches every floor cell the pilot reached.

    A floor cell is read off the pilot rows rather than off the segment, so `coverage_floor_vars`
    may name characteristics that are not `segment_vars`: a segment then spans several floor
    cells, and the segment rescuing one of them is the most populous segment holding a pilot row
    in it. That is what lets the floor be defined on tenure and vacancy status, which the
    allocator joins on but which do not split a segment.

    The added segments are additive. Nothing already selected is displaced, so every building the
    rank cut alone would have produced is still produced and the run builds correspondingly more
    than `num_datapoints`.

    Args:
        pilot_df: The pilot sample, one row per drawn building, carrying every floor cell column
        segment_counts: One row per segment the pilot reached, carrying a `count` column
        top_segments: The segments the rank cut kept, a subset of `segment_counts`
        segment_cols: Columns whose combination defines a segment
        coverage_floor_vars: Columns whose combination defines a floor cell

    Returns:
        `top_segments` with one added segment for each floor cell it did not already cover

    Raises:
        ValueError: If a name in `coverage_floor_vars` is not a column of the pilot sample
    """

    unknown = sorted(set(coverage_floor_vars) - set(pilot_df.columns))
    if unknown:
        raise ValueError(
            f"coverage_floor_vars {unknown} are not sampled characteristics, so no pilot row "
            f"carries them; every floor cell column must be a segment_var or an ancestor of one"
        )

    cell_cols = list(dict.fromkeys(coverage_floor_vars))
    pair_cols = list(dict.fromkeys([*cell_cols, *segment_cols]))
    # One row per (floor cell, segment) pair the pilot produced, carrying the segment's pilot count
    cell_segments = pilot_df.select(pair_cols).unique().join(segment_counts, on=segment_cols, how="left")

    covered_cells = cell_segments.join(top_segments.select(segment_cols), on=segment_cols, how="semi")
    uncovered_cells = (
        cell_segments.select(cell_cols).unique()
        .join(covered_cells.select(cell_cols).unique(), on=cell_cols, how="anti")
    )
    if uncovered_cells.height == 0:
        print(f"Coverage floor over {cell_cols} adds nothing: the rank cut already reaches every cell")
        return top_segments

    # A rescuing segment can be the strongest in more than one uncovered cell, so it is taken once
    rescued = (
        cell_segments.join(uncovered_cells, on=cell_cols, how="semi")
        .sort(["count", *segment_cols], descending=[True, *([False] * len(segment_cols))])
        .unique(subset=cell_cols, keep="first", maintain_order=True)
        .select(top_segments.columns)
        .unique(subset=segment_cols, keep="first", maintain_order=True)
    )
    print(f"Coverage floor over {cell_cols} adds {rescued.height} segments for the "
          f"{uncovered_cells.height} cells the rank cut left uncovered")
    return pl.concat([top_segments, rescued], how="vertical")


def take_samples_per_segment(df: pl.DataFrame, segment_cols: list[str], num_samples_per_segment: int,
                             random_seed: int = RANDOM_SEED) -> pl.DataFrame:
    """Take a random `num_samples_per_segment` rows out of each segment.

    Every row is given a uniform variate from a generator seeded with `random_seed`, and each
    segment keeps the rows with the smallest variates, so the take is uniform over the segment
    and reproducible for a given seed and input frame. Segments holding fewer rows than asked
    for contribute all of them.

    Args:
        df: Frame of candidate buildings, one row per building
        segment_cols: Columns whose combination defines a segment
        num_samples_per_segment: Rows to keep per segment
        random_seed: Seed making the take reproducible

    Returns:
        Frame holding min(num_samples_per_segment, segment size) rows per segment
    """

    # rng = np.random.default_rng(random_seed)
    # return (
        # df.with_columns(pl.Series("_take_draw", rng.random(df.height), dtype=pl.Float64))
        # .sort("_take_draw")
        # .group_by(segment_cols, maintain_order=True)
        # .head(num_samples_per_segment)
        # .drop("_take_draw")
    # )

    df_pd = df.to_pandas()

    # Use apply with a lambda function to dynamically match the minimum threshold
    sampled_pd = (
        df_pd.groupby(segment_cols, group_keys=False)
        .apply(lambda x: x.sample(n=min(len(x), num_samples_per_segment), random_state=random_seed))
    )

    # Restore the original row sequence layout
    sampled_pd = sampled_pd.sort_index()

    return pl.from_pandas(sampled_pd)

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
        if not pathlib.Path(config).is_absolute():
            config_path = (pathlib.Path(__file__).resolve().parent / ".." / ".." / ".."/ "resources" / config).resolve()
        else:
            config_path = pathlib.Path(config)
    else:
        # from same directory as this script
        config_path = pathlib.Path(__file__).parent / "sampler_config.yaml"
    config = {}
    if config_path.exists():
        with open(config_path, 'r') as f:
            print(f"Loading config from {config_path}")
            config = yaml.safe_load(f)

    segment_vars = set(config.get('segment_vars', []))
    # Sorted so the segment grouping, and therefore the take within it, does not depend on set order
    segment_cols = sorted(segment_vars)
    initial_sample_size = config.get('segment_selection_sample_size', 10000000)
    num_samples_per_segment = config.get('num_samples_per_segment', DEFAULT_NUM_SAMPLES_PER_SEGMENT)
    # Absent, the selection is the rank cut alone; see add_coverage_floor_segments
    coverage_floor_vars = list(config.get('coverage_floor_vars', []))
    initial_samples_df = None
    init_start_time = time.time()
    print(project, num_datapoints, output, segment_vars)
    print(f"Performing initial sampling with {initial_sample_size} samples to pick the segments")
    initial_samples_df = pl.from_pandas(sample_all(pathlib.Path(project), initial_sample_size, segment_vars=segment_vars))
    print(f"Initial sampling completed in {time.time() - init_start_time:.2f} seconds. Sample size: {initial_samples_df.shape}")
    initial_samples_df = initial_samples_df.drop("Building")
    num_segments = num_datapoints // num_samples_per_segment
    segment_counts = initial_samples_df.group_by(segment_cols, maintain_order=True).agg(pl.len().alias("count"))
    # Select the most populous segments, using segment values to break count ties reproducibly.
    top_segments = (
        segment_counts
        .sort(["count", *segment_cols], descending=[True, *([False] * len(segment_cols))])
        .limit(num_segments)
    )
    if coverage_floor_vars:
        top_segments = add_coverage_floor_segments(initial_samples_df, segment_counts, top_segments,
                                                   segment_cols, coverage_floor_vars)
    new_df = initial_samples_df.join(top_segments, on=segment_cols, validate="m:1", how="left", maintain_order="left")
    valid_df = new_df.filter(~pl.col('count').is_null())
    valid_df = valid_df.drop("count")
    limited_df = take_samples_per_segment(valid_df, segment_cols, num_samples_per_segment)
    new_total = limited_df.shape[0]
    if new_total < num_datapoints:
        print(f"Will be sampling {new_total} samples instead of {num_datapoints} due to rounding")
    limited_df = limited_df.with_row_index("Building", offset=1)
    initial_samples_df = limited_df.to_pandas()
    final_start_time = time.time()
    print(f"Performing final sampling with {num_segments} segments of {num_samples_per_segment} samples each")
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
