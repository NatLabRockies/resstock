# ResStock Change Documents

A change document records **what changed in ResStock and whether it is correct**. One document per
change, where a change is anything that can move ResStock inputs or outputs: a baseline methodology
update, a housing-characteristic distribution refresh, a new or modified upgrade option, a workflow
change, a dependency version bump (OpenStudio-HPXML, EnergyPlus, buildstockbatch), or a bug fix.

These are written by the **implementer** and reviewed on GitHub. They are not publication quality,
but each must stand alone: someone familiar with building simulation and the general concept of
ResStock should be able to evaluate the change, qualitatively and quantitatively, without asking the
author questions.

## Index

| Change | Date | Type | Status | Verdict |
|---|---|---|---|---|
| [OpenStudio-HPXML 1.11 and option-based BuildResidentialHPXML arguments](2026-08-oshpxml-1-11-and-options-args/) | 2026-08 | baseline methodology + dependency bump | draft | REVIEW NEEDED |

## Layout

```
docs/change_docs/
├── README.md                              this index
└── YYYY-MM-<change_id>/
    ├── README.md                          the change document
    └── images/                            figures referenced by it
```

- The folder name is the `change_id` from the document's §0 metadata, prefixed with the year and
  month so the directory sorts chronologically.
- The document is named `README.md` so that GitHub renders it, with figures inline, as soon as a
  reviewer opens the folder.
- `images/` holds only figures the document references. Paths in the document are relative
  (`images/fig_4_5_a_enduse_percent.png`) and are **case-sensitive on GitHub**, so they must match
  the filenames exactly.

## What belongs here, and what does not

**Committed:** the document and its figures.

**Not committed:** the analysis scripts, notebooks, captured console output, intermediate parquet
extracts, and any other working files. Those stay with the change's working directory. Keeping them
out is deliberate — these folders are read by reviewers, not executed, and analysis code has a
different lifecycle from the conclusions it produced.

Because the scripts are not here, each document must describe **where its data came from and how it
was processed** — the run paths, the access method, the weighting, the definition of every derived
quantity — rather than naming a script. A reader should be able to reproduce any number in the
document from that description alone. See the appendix of the change document linked above for the
shape this takes.

## Adding a change document

1. Copy `ResStock_Change_Template.md` from the ResStock Features SharePoint
   (`10_ResStock_Features/Change Documentation/`) into a working folder and fill it in there,
   alongside your analysis code.
2. Strip the template scaffolding. Two things must be gone: every line beginning with `>`
   (guidance and examples), and the `*Required.*` / `*Required if …*` / `*Optional.*` marker under
   each heading — those tell the author whether a section is mandatory and mean nothing to a
   reader. A section that does not apply is still marked `N/A` **with a reason**, and that line
   stays.
   ```bash
   sed '1,/^<!-- BEGIN CHANGE DOCUMENT -->$/d; /^>/d; /^\*\(Required\|Optional\).*\*$/d' ResStock_Change_Template.md | cat -s > README.md
   ```
   Then verify no blockquotes, no `*Required*` markers, no `[FILL]` markers, and that every
   surviving `TBD` is a deliberate, explained gap.
3. Create `docs/change_docs/YYYY-MM-<change_id>/`, copy in the document as `README.md` and its
   figures under `images/`, and add a row to the index above.
4. Open a PR. Link the folder in the PR description so reviewers get the rendered document — the
   **Files changed** tab shows Markdown as a source diff, which is good for line comments but not
   for reading.

## Reviewing

The document is the unit of review, not the diff. Read it rendered, then comment on specific lines
in the diff. The things worth pushing on:

- **§1.3 is the hypothesis register and must have been written before §4.** Predictions first,
  reconciliation in §5.1. A hypothesis that turned out right for the wrong reason should say so.
- **Every number traces to a named source**, and every table and figure has an interpretation.
- **Observation is separated from inference.** An arithmetic bound is not a measured coupling.
- **Skipped sections are marked `N/A` with a reason**, never deleted. An empty finding in an
  analysis that was not run is not a null result.
- **The verdict names what was not verified.** Distinguish an open *investigation* (cause unknown)
  from an open *decision* (cause known, value choice outstanding).
