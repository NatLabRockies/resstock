.. _testing_index:

Testing Infrastructure
======================

This section documents the testing framework for validating ResStock batch results,
ensuring CSV output consistency, and checking input integrity for `buildstock.csv`
and `options_lookup.tsv`.

Tests include:

- CLI tests for input validation
- Regression tests comparing simulation outputs
- Structural integrity checks for input files

.. toctree::
   :maxdepth: 2

   integrity_checks
   test_analysis_tools