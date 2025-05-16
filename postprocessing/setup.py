# ResStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
#!/usr/bin/env python3

import os
from setuptools import setup

# get key package details from py_pkg/__version__.py
about = {}  # type: ignore
here = os.path.abspath(os.path.dirname(p=__file__))
with open(os.path.join(here, 'resstockpostproc', '__version__.py')) as f:
    exec(f.read(), about)

# load the README file and use it as the long_description for PyPI
with open('README.md', 'r') as f:
    readme = f.read()

# package configuration - for reference see:
# https://setuptools.readthedocs.io/en/latest/setuptools.html#id9
setup(
    name=about['__title__'],
    description=about['__description__'],
    long_description=readme,
    long_description_content_type='text/markdown',
    version=about['__version__'],
    author=about['__author__'],
    author_email=about['__author_email__'],
    url=about['__url__'],
    packages=['resstockpostproc'],
    include_package_data=True,
    package_data={
        'resstockpostproc': [
            'resources/gisdata/*.geojson', 
            'resources/gisdata/*.csv',
            'resources/publication/sdr_column_definitions.csv'
        ],
    },
    license=about['__license__'],
    zip_safe=False,
    entry_points={
        'console_scripts': ['resstockpostproc=resstockpostproc.entry_points:main'],
    },
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Programming Language :: Python :: 3.11',
    ],
    keywords='resstock postprocessing',
    python_requires=">=3.11",
    install_requires=[
        'pandas',
        'geopandas',
        'plotly',
        'pyarrow',
        'fsspec',
        's3fs',
        'polars',
        'buildstock_query @ git+https://github.com/NREL/buildstock-query@main'
    ],
    extras_require={
        'dev': [
            'pytest',
            'black',
            'autopep8',
            'ipykernel',
        ],
    }
)
