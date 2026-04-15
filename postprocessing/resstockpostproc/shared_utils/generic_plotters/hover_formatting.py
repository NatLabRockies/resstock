"""Shared helpers for compact hover-value formatting across plotters."""

import math


def format_compact_number(value: float | int | None) -> str:
    """Format a numeric value with 2 decimals and K/M/B/T suffixes."""
    if value is None:
        return ""

    numeric = float(value)
    abs_numeric = abs(numeric)
    for threshold, suffix in (
        (1_000_000_000_000, "T"),
        (1_000_000_000, "B"),
        (1_000_000, "M"),
        (1_000, "K"),
    ):
        if abs_numeric >= threshold:
            return f"{numeric / threshold:,.2f}{suffix}"
    return f"{numeric:,.2f}"


def _is_percentage_quantity(quantity_title: str) -> bool:
    quantity = quantity_title.strip().lower()
    return "%" in quantity or "percent" in quantity


def format_compact_hover_value(value: float | int | None, quantity_title: str) -> str:
    """Format hover values compactly without repeating physical units from the axis."""
    base = format_compact_number(value)
    if not base:
        return ""
    if _is_percentage_quantity(quantity_title):
        return f"{base}%"
    return base


def format_count_value(value: float | int | None) -> str:
    """Format a count-like value as a rounded integer with separators."""
    if value is None:
        return ""
    rounded = int(math.floor(float(value) + 0.5))
    return f"{rounded:,}"
