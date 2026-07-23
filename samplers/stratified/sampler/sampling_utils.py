from functools import cache
import pathlib
import time
from joblib import Parallel, delayed
import random

TSVTuple = tuple[dict[tuple[str, ...], list[float]], list[str], list[str]]


def read_char_tsv(file_path: pathlib.Path) -> TSVTuple:
    dep_cols = []
    opt_cols = []
    group2probs = {}
    with open(file_path) as file:
        for line_num, line in enumerate(file):
            if line[0] == '#':
                continue
            if line_num == 0:
                for header in line.split("\t"):
                    if header.startswith("Dependency="):
                        dep_cols.append(header.removeprefix('Dependency=').strip())
                    elif header.startswith("Option="):
                        opt_cols.append(header.removeprefix("Option=").strip())
            else:
                line_array = line.split("\t")
                dep_val = tuple(line_array[:len(dep_cols)])
                opt_val = [float(v) for v in line_array[len(dep_cols): len(dep_cols) + len(opt_cols)]]
                group2probs[dep_val] = opt_val

    return group2probs, dep_cols, opt_cols


@cache
def get_param2tsv(project_dir: pathlib.Path) -> dict[str, TSVTuple]:
    characteristics_dir = project_dir / "housing_characteristics"
    s_time = time.time()
    param2tsv_path = {tsv_path.name.removesuffix('.tsv'): tsv_path for tsv_path in
                      sorted(characteristics_dir.glob('*.tsv'))}
    param2tsv = {}
    with Parallel(n_jobs=-2) as parallel:
        def read_tsv(param, tsv_path):
            return (param, read_char_tsv(tsv_path))
        res = parallel(map(delayed(read_tsv), *zip(*param2tsv_path.items())))
    param2tsv = dict(res)
    print(f"Got Param2tsv in {time.time()-s_time:.2f} seconds")
    return param2tsv


def get_samples(probs: list[float], options: list[str], num_samples: int) -> list[str]:
    """Returns a list of samples chosen from the options list as per the probability distribution in probs using
       simple random sampling.
    Args:
        probs (list[float]): The probabilities for the options.
        options (list[str]): The options to sample from.
        num_samples (int): Number of samples to return.

    Returns:
        list[str]: The list of samples.
    """
    return random.choices(options, weights=probs, k=num_samples)
