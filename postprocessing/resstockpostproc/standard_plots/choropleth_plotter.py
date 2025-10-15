"""
Choropleth plotter for standard plots.
Produces state- or county-level choropleth maps using Plotly.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Any

import polars as pl
import plotly.colors as pc
import plotly.graph_objects as go
from plotly.subplots import make_subplots

try:  # shapely is optional; used for centroid calculations if available
    from shapely.geometry import shape  # type: ignore[import-not-found]
except Exception:  # noqa: BLE001 - keep plotter functional without shapely
    shape = None

from resstockpostproc.standard_plots.base_plotter import BasePlotter
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup, QuantityType

__all__ = ["ChoroplethPlotter"]


_STATE_ABBR_TO_NAME = {
    "AL": "Alabama",
    "AK": "Alaska",
    "AZ": "Arizona",
    "AR": "Arkansas",
    "CA": "California",
    "CO": "Colorado",
    "CT": "Connecticut",
    "DE": "Delaware",
    "DC": "District of Columbia",
    "FL": "Florida",
    "GA": "Georgia",
    "HI": "Hawaii",
    "ID": "Idaho",
    "IL": "Illinois",
    "IN": "Indiana",
    "IA": "Iowa",
    "KS": "Kansas",
    "KY": "Kentucky",
    "LA": "Louisiana",
    "ME": "Maine",
    "MD": "Maryland",
    "MA": "Massachusetts",
    "MI": "Michigan",
    "MN": "Minnesota",
    "MS": "Mississippi",
    "MO": "Missouri",
    "MT": "Montana",
    "NE": "Nebraska",
    "NV": "Nevada",
    "NH": "New Hampshire",
    "NJ": "New Jersey",
    "NM": "New Mexico",
    "NY": "New York",
    "NC": "North Carolina",
    "ND": "North Dakota",
    "OH": "Ohio",
    "OK": "Oklahoma",
    "OR": "Oregon",
    "PA": "Pennsylvania",
    "RI": "Rhode Island",
    "SC": "South Carolina",
    "SD": "South Dakota",
    "TN": "Tennessee",
    "TX": "Texas",
    "UT": "Utah",
    "VT": "Vermont",
    "VA": "Virginia",
    "WA": "Washington",
    "WV": "West Virginia",
    "WI": "Wisconsin",
    "WY": "Wyoming",
    "PR": "Puerto Rico",
}

_STATE_NAME_TO_ABBR = {name: abbr for abbr, name in _STATE_ABBR_TO_NAME.items()}


class ChoroplethPlotter(BasePlotter):
    """Build a state or county level choropleth map."""

    _county_geojson: dict[str, Any] | None = None
    _county_label_map: dict[str, str] | None = None
    _state_label_cache: dict[str, tuple[float, float]] | None = None

    def create_plot(
        self,
        data: pl.DataFrame,
        plot_spec: PlotSpec,
        *,
        show_labels: bool = True,
    ) -> go.Figure:
        """Create a choropleth map for the provided data."""
        if plot_spec.group_by is None:
            raise ValueError("Choropleth plots require a group_by column.")
        if isinstance(plot_spec.quantity, QuantityGroup):  # defensive guard; should already be prevented
            raise ValueError("Choropleth plots require a single quantity column.")

        quantity_col = str(plot_spec.quantity)
        group_col = plot_spec.group_by

        df = data.filter(pl.col(group_col).is_not_null() & pl.col(quantity_col).is_not_null())
        if df.is_empty():
            fig = go.Figure()
            self.theme.apply_layout(fig)
            fig.add_annotation(
                text="No data available for choropleth plot",
                x=0.5,
                y=0.5,
                xref="paper",
                yref="paper",
                showarrow=False,
            )
            return fig

        z_min, z_max = df.select(
            pl.min(quantity_col).alias("min"), pl.max(quantity_col).alias("max")
        ).row(0)
        z_min = float(z_min)
        z_max = float(z_max)
        if z_min == z_max:
            delta = abs(z_min) if z_min else 1.0
            z_min -= delta * 0.05
            z_max += delta * 0.05

        colorscale, z_min, z_max = self._choose_colorscale(z_min, z_max, plot_spec)
        quantity_title = self.get_quantity_title(plot_spec)

        upgrades = df["upgrade_name"].unique(maintain_order=True).to_list()
        n_cols = max(1, len(upgrades))
        fig = make_subplots(
            rows=1,
            cols=n_cols,
            specs=[[{"type": "choropleth"} for _ in range(n_cols)]],
            subplot_titles=[self.format_label(str(up)) for up in upgrades] if upgrades else (),
        )

        level = "state" if group_col == "in.state" else "county"
        geojson = self._load_county_geojson() if level == "county" else None

        for idx, upgrade_name in enumerate(upgrades):
            subset = df.filter(pl.col("upgrade_name") == upgrade_name)
            if subset.is_empty():
                continue

            locations, labels = self._extract_locations(subset[group_col].to_list(), level)
            values = subset[quantity_col].to_list()
            model_counts = subset["model_count"].to_list()
            text_values = (
                self._build_text_labels(level, values, plot_spec, quantity_title)
                if show_labels
                else None
            )

            trace = go.Choropleth(
                locations=locations,
                z=values,
                locationmode="USA-states" if level == "state" else None,
                geojson=geojson,
                featureidkey="id" if level == "county" else None,
                coloraxis="coloraxis",
                marker_line_width=1.4 if level == "state" else 0.6,
                marker_line_color="rgba(0,0,0,0.85)",
                customdata=list(zip(labels, model_counts)),
                hovertemplate=self._build_hovertemplate(quantity_title),
            )
            if text_values:
                trace.update(
                    text=text_values,
                    hovertemplate=self._build_hovertemplate(quantity_title),
                )
            fig.add_trace(trace, row=1, col=idx + 1)

            if text_values:
                label_positions = self._state_label_positions()
                latitudes: list[float] = []
                longitudes: list[float] = []
                texts: list[str] = []
                for loc, text in zip(locations, text_values):
                    coords = label_positions.get(loc)
                    if not coords or not text:
                        continue
                    latitudes.append(coords[0])
                    longitudes.append(coords[1])
                    texts.append(text)
                if latitudes:
                    scatter = go.Scattergeo(
                        lat=latitudes,
                        lon=longitudes,
                        text=texts,
                        mode="text",
                        textfont={"color": "rgba(0,0,0,0.75)", "size": 12},
                        showlegend=False,
                    )
                    fig.add_trace(scatter, row=1, col=idx + 1)

            fig.update_geos(
                scope="usa",
                fitbounds="locations",
                showcountries=False,
                showsubunits=False,
                showlakes=False,
                showframe=False,
                showcoastlines=False,
                bgcolor="rgba(0,0,0,0)",
                projection={"type": "albers usa"},
                row=1,
                col=idx + 1,
            )

        fig.update_layout(
            coloraxis={
                "colorscale": colorscale,
                "cmin": z_min,
                "cmax": z_max,
                "colorbar": {"title": quantity_title},
            }
        )
        self.theme.apply_layout(fig)
        fig.update_layout(margin={"l": 10, "r": 70, "t": 90, "b": 40})
        return fig

    @staticmethod
    def _choose_colorscale(
        z_min: float,
        z_max: float,
        plot_spec: PlotSpec,
    ) -> tuple[list[str], float, float]:
        """Select colorscale and enforce range for percent savings."""
        if plot_spec.quantity_type == QuantityType.percent_savings:
            # Fixed diverging range: -100% (orange) → 0 (white) → +100% (blue)
            colorscale = [
                [0.0, "#EA580C"],  # deep orange
                [0.5, "#FFFFFF"],  # neutral white
                [1.0, "#1D4ED8"],  # deep blue
            ]
            return colorscale, -100.0, 100.0

        if z_min < 0 < z_max:
            return pc.diverging.RdBu[::-1], z_min, z_max
        if z_max <= 0:
            return pc.sequential.Reds[::-1], z_min, z_max
        return pc.sequential.Blues, z_min, z_max

    @staticmethod
    def _build_hovertemplate(quantity_title: str) -> str:
        """Return a hover template string with location, value, and model count."""
        return (
            "%{customdata[0]}<br>"
            f"{quantity_title}: %{{z:,.2f}}<br>"
            "Number of models: %{customdata[1]:,}"
            "<extra></extra>"
        )

    def _build_text_labels(
        self,
        level: str,
        values: list[float],
        plot_spec: PlotSpec,
        quantity_title: str,
    ) -> list[str] | None:
        """Provide inline labels for state-level maps."""
        if level != "state":
            return None

        qtype = plot_spec.quantity_type
        labels: list[str] = []
        for value in values:
            if value is None:
                labels.append("")
                continue
            if qtype == QuantityType.percent_savings or "Percent" in quantity_title:
                labels.append(f"{value:.1f}%")
            elif abs(value) >= 1_000_000:
                labels.append(f"{value/1_000_000:.1f}M")
            elif abs(value) >= 1_000:
                labels.append(f"{value/1_000:.1f}K")
            else:
                labels.append(f"{value:.1f}")
        return labels

    @classmethod
    def _extract_locations(cls, raw_values: list[Any], level: str) -> tuple[list[str], list[str]]:
        """Return location ids and human readable labels for the requested level."""
        if level == "state":
            locations = [str(val).upper() for val in raw_values]
            labels = [
                f"{_STATE_ABBR_TO_NAME.get(loc, loc)} ({loc})"
                for loc in locations
            ]
            return locations, labels

        # County level
        fips_codes, labels = [], []
        county_labels = cls._load_county_labels()
        for raw in raw_values:
            code = str(raw)
            fips = cls._normalize_county_code(code)
            label = county_labels.get(code) or county_labels.get(fips) or code
            if label and "," in label:
                state_abbr, locality = [part.strip() for part in label.split(",", 1)]
                state_name = _STATE_ABBR_TO_NAME.get(state_abbr, state_abbr)
                label = f"{locality}, {state_name}"
            labels.append(label)
            fips_codes.append(fips)
        return fips_codes, labels

    @staticmethod
    def _normalize_county_code(code: str) -> str:
        """Convert ResStock county codes (GISJOIN) to 5-digit FIPS strings."""
        if not code:
            return code
        if code.startswith("G") and len(code) >= 4:
            core = code[1:-1]
            state = core[:2]
            county_number = int(core[2:]) if core[2:] else 0
            return f"{state}{county_number:03d}"
        return code if len(code) == 5 else code.zfill(5)

    @classmethod
    def _load_county_geojson(cls) -> dict[str, Any]:
        if cls._county_geojson is None:
            path = cls._resources_dir() / "us_counties.geojson"
            with path.open("r", encoding="utf-8") as f:
                cls._county_geojson = json.load(f)
        return cls._county_geojson

    @classmethod
    def _load_county_labels(cls) -> dict[str, str]:
        if cls._county_label_map is None:
            path = cls._resources_dir() / "county_lookup_table.csv"
            mapping: dict[str, str] = {}
            with path.open("r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                for row in reader:
                    code = row["original_FIP"]
                    label = row["long_name"]
                    mapping[code] = label
                    fips = cls._normalize_county_code(code)
                    mapping.setdefault(fips, label)
            cls._county_label_map = mapping
        return cls._county_label_map

    @staticmethod
    def _resources_dir() -> Path:
        return Path(__file__).resolve().parent.parent / "resources" / "gisdata"

    @classmethod
    def _state_label_positions(cls) -> dict[str, tuple[float, float]]:
        """Return representative lat/lon for each state derived from GeoJSON."""
        if cls._state_label_cache is not None:
            return cls._state_label_cache

        path = cls._resources_dir() / "us_states.geojson"
        mapping: dict[str, tuple[float, float]] = {}
        if path.exists():
            with path.open("r", encoding="utf-8") as f:
                data = json.load(f)
            for feature in data.get("features", []):
                props = feature.get("properties", {})
                abbr = (
                    props.get("postal")
                    or props.get("state_abbr")
                    or props.get("STUSPS")
                    or _STATE_NAME_TO_ABBR.get(str(props.get("name", "")).strip())
                )
                geometry = feature.get("geometry")
                if not abbr or not geometry:
                    continue
                lat, lon = cls._centroid_from_geometry(geometry)
                mapping[abbr.upper()] = (lat, lon)

        # Provide safe fallbacks / tweaks for insets
        mapping.setdefault("AK", (63.0, -152.0))
        mapping.setdefault("HI", (20.9, -157.5))
        mapping.setdefault("PR", (18.2, -66.5))
        mapping.setdefault("DC", (38.9, -77.0))

        cls._state_label_cache = mapping
        return mapping

    @staticmethod
    def _centroid_from_geometry(geometry: dict[str, Any]) -> tuple[float, float]:
        """Compute a representative point from GeoJSON geometry."""
        if shape is not None:
            try:
                geom = shape(geometry)
                point = geom.representative_point()
                return float(point.y), float(point.x)
            except Exception:  # noqa: BLE001
                pass

        coords: list[tuple[float, float]] = []

        def _collect(points: Any) -> None:
            if not points:
                return
            if isinstance(points[0], (int, float)):
                lon, lat = points
                coords.append((float(lat), float(lon)))
            else:
                for item in points:
                    _collect(item)

        _collect(geometry.get("coordinates", []))
        if not coords:
            return 0.0, 0.0
        lat = sum(pt[0] for pt in coords) / len(coords)
        lon = sum(pt[1] for pt in coords) / len(coords)
        return lat, lon
