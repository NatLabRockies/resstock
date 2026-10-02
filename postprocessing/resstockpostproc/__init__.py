# ResStock™, Copyright (c) 2026 Alliance for Energy Innovation, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
"""
Publication postprocessing for ResStock BuildStockBatch results.

The stable public entry point for external callers (e.g. buildstockbatch) is
``export_metadata_and_annual_results``, importable either from the package root
or from its home module ``resstockpostproc.process_bsb_results``. Both paths
are supported; changes to this entry point's signature are breaking changes and
must be noted in the changelog.
"""

from resstockpostproc.__version__ import __version__

__all__ = ["__version__", "export_metadata_and_annual_results"]


def __getattr__(name):
    # Lazy re-export (PEP 562) so `import resstockpostproc` stays lightweight and
    # doesn't pull in the full pipeline's dependencies until actually used.
    if name == "export_metadata_and_annual_results":
        from resstockpostproc.process_bsb_results import export_metadata_and_annual_results  # noqa: PLC0415

        return export_metadata_and_annual_results
    raise AttributeError(f"module 'resstockpostproc' has no attribute {name!r}")
