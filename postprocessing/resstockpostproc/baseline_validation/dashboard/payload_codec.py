"""Gzip + base64 payload encoding for dashboard data files.

The dashboard loads its data via ``<script src>`` tags so it works over
``file://`` with no CORS or server headers. To keep those files small, the
canonical writer emits the payload gzipped and base64-encoded inside the
script; the viewer decodes it at load time (native ``DecompressionStream``
or the bundled fflate fallback). Base64 keeps the bytes ASCII-safe inside a
JS string literal; the ~33% base64 overhead is negligible against the
~95% gzip reduction on this highly repetitive data.
"""

from __future__ import annotations

import base64
import gzip


def encode_gzip_b64(text: str) -> str:
    """Gzip a UTF-8 string and return it base64-encoded (ASCII)."""
    gz = gzip.compress(text.encode("utf-8"), compresslevel=9, mtime=0)
    return base64.b64encode(gz).decode("ascii")
