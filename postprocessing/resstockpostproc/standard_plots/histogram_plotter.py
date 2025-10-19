import textwrap

import plotly.graph_objects as go
import polars as pl
from plotly.subplots import make_subplots

from resstockpostproc.standard_plots.base_plotter import BasePlotter
from resstockpostproc.standard_plots.schema.plot_spec import PlotSpec
from resstockpostproc.standard_plots.schema.workflow_schema import QuantityGroup

__all__ = ["HistogramPlotter"]


class HistogramPlotter(BasePlotter):
    def create_plot(self, data: pl.DataFrame, plot_spec: PlotSpec) -> go.Figure:
        """Create and return a histogram figure based on *plot_spec*."""
        # Histograms currently support *single* quantity only.
        if isinstance(plot_spec.quantity, QuantityGroup):
            raise ValueError("Histogram plots require a single quantity - not a stacked QuantityGroup")

        facet_col: str | None = plot_spec.group_by if plot_spec.group_by else None
        assert isinstance(plot_spec.quantity, str)  # noqa: S101 Use of `assert` detected
        return self.create_histogram_plot(
            data=data,
            name=self.get_quantity_title(plot_spec),
            facet_column=facet_col,
        )

    def create_histogram_plot(
        self,
        *,
        data: pl.DataFrame,
        name: str,
        facet_column: str | None = None,
    ) -> go.Figure:
        """
        Visualise an explicit frequency table with a bar chart.

        Parameters
        ----------
        data :
            Polars DataFrame produced by `prepare_data_for_histogram_plot` and
            therefore expected to contain at least
            ['bin', 'bin_left', 'bin_right', 'count', 'upgrade_name']
            plus an optional `facet_column`.
        name :
            Human-readable label for X-axis (will be run through `format_label`).
        facet_column :
            Optional column to facet by (creates additional columns of sub-plots).

        Returns
        -------
        go.Figure
        """
        # ------------------------------------------------------------------
        # 1. Derive helper columns (centre & bar-width)
        # ------------------------------------------------------------------
        core_w = (
            data.filter((pl.col("bin") >= 0) & (pl.col("bin") < 100))  # noqa: PLR2004
            .select((pl.col("bin_right") - pl.col("bin_left")).alias("w"))
            .get_column("w")[0]  # <- one scalar, no shape error
        )

        # 1b.  Finite bounds of the 1%-to-99% range
        q1 = data.filter(pl.col("bin") == 0).select(pl.col("bin_left").alias("q1")).get_column("q1")[0]
        q99 = data.filter(pl.col("bin") == 99).select(pl.col("bin_right").alias("q99")).get_column("q99")[0]  # noqa: PLR2004

        # 1c.  Finite bar centres
        df = data.with_columns(
            pl.when(pl.col("bin") == -1)
            .then(q1 - core_w)  # centre left-tail
            .when(pl.col("bin") == 100)  # noqa: PLR2004
            .then(q99 + core_w)  # centre right-tail
            .otherwise((pl.col("bin_left") + pl.col("bin_right")) / 2.0)
            .alias("_bin_center"),
            pl.when(pl.col("bin").is_in([-1, 100]))
            .then(core_w * 2)  # wider tail bars
            .otherwise(core_w)
            .alias("_bar_width"),
        )

        # ------------------------------------------------------------------
        # 2. Prepare facet grid (rows = facets, columns = upgrades)
        # ------------------------------------------------------------------
        upgrades = df["upgrade_name"].unique(maintain_order=True).to_list()
        facet_values = df[facet_column].unique(maintain_order=True).to_list() if facet_column else [None]

        n_rows, n_cols = len(facet_values), len(upgrades)
        h_spacing = 0.1 * (1 / max(n_cols, 1))
        v_spacing = 0.1 * (1 / max(n_rows, 1))
        fig = make_subplots(
            rows=n_rows,
            cols=n_cols,
            shared_yaxes="all",
            shared_xaxes="all",
            row_titles=[str(f) for f in facet_values] if facet_column else None,
            column_titles=[str(u) for u in upgrades],
            horizontal_spacing=h_spacing,
            vertical_spacing=v_spacing,
        )

        # ------------------------------------------------------------------
        # 3. Add one Bar trace per upgrade *and* facet
        # ------------------------------------------------------------------
        for r, facet_val in enumerate(facet_values, start=1):
            for c, upgrade in enumerate(upgrades, start=1):
                mask = pl.col("upgrade_name") == upgrade
                if facet_column:
                    mask &= pl.col(facet_column) == facet_val

                sub = df.filter(mask)
                if sub.is_empty():
                    continue

                fig.add_bar(
                    x=sub["_bin_center"].to_list(),
                    y=sub["count"].to_list(),
                    width=sub["_bar_width"].to_list(),
                    name=upgrade,
                    marker_color=self.theme.upgrade_palette.get(upgrade),
                    showlegend=(r == 1),  # one legend entry per upgrade
                    legendgroup=upgrade,
                    customdata=list(zip(sub["bin_left"].to_list(), sub["bin_right"].to_list())),  # type: ignore[arg-type]
                    hovertemplate="%{customdata[0]:.1f} to %{customdata[1]:.1f}<br>Count: %{y}<extra></extra>",
                    row=r,
                    col=c,
                )

        # ------------------------------------------------------------------
        # 4. Layout & styling
        # ------------------------------------------------------------------
        # No gaps between grouped bars
        x_min = q1 - 2 * core_w  # left-tail bar starts here
        x_max = q99 + 2 * core_w  # right-tail bar ends here
        y_max = df["count"].max()

        fig.update_xaxes(range=[x_min, x_max])
        fig.update_yaxes(range=[0, y_max])

        # No gaps between grouped bars
        fig.update_layout(
            barmode="group",
            bargap=0,
            bargroupgap=0,
            template=self.theme.template,
            legend_title_text="Upgrade",
        )
        # Apply theme before axis tweaks (so theme rules don't overwrite them)
        self.theme.apply_layout(fig)

        # ── 4 b.  Axis styling & titles ─────────────────────────────────────
        # grid on all y-axes
        fig.update_yaxes(gridcolor="lightgray", gridwidth=0.5)

        #  Same numeric ranges everywhere
        fig.update_xaxes(range=[x_min, x_max])
        fig.update_yaxes(range=[0, y_max])

        # Put Y-axis title and ticks only on the left column
        for r in range(1, n_rows + 1):
            fig.update_yaxes(title_text="Number of models in bin", row=r, col=1)
            for c in range(2, n_cols + 1):
                fig.update_yaxes(title_text="", showticklabels=False, row=r, col=c)

        # Put X-axis title only on the bottom row
        for c in range(1, n_cols + 1):
            for r in range(1, n_rows + 1):
                fig.update_xaxes(title_text="", row=r, col=c)
        # ── 4c.  Facet annotation wrapping & overall width ─────────────────
        if facet_column:
            wrap = self.theme.facet_title_width
            fig.for_each_annotation(
                lambda a: a.update(
                    text="<br>".join(
                        textwrap.wrap(
                            a.text.split("=")[-1].strip() if a.text is not None else "",
                            width=wrap,
                            break_long_words=False,
                        )
                    )
                )
            )
        fig.add_annotation(
            text=name,
            xref="paper",
            yref="paper",
            x=0.5,
            y=-0.07,  # center at bottom
            xanchor="center",
            yanchor="top",
            showarrow=False,
            font={"size": 14},
            name="xtitle",
        )
        #  Adjust figure width
        fig.update_layout(width=max(1000, min(1920, n_cols * self.theme.facet_width)), margin={"b": 100})
        return fig
