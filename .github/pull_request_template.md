## Pull Request Description
[description here]

### Related Pull Requests
[related PRs from different repositories]

### Related Issues
[What issue(s) is the PR addressing]

## Checklist

#### Required:
- [ ] Add to the [changelog_dev.rst file](https://github.com/NREL/resstock/blob/develop/docs/technical_development_guide/source/changelog/changelog_dev.rst)
- [ ] No unexpected regression test changes on CI (comparison artifacts have been checked)
- [ ] Update documentation (one is required)
     - [ ] [Technical reference guide](https://github.com/NREL/resstock/tree/develop/docs/technical_reference_guide)
     - [ ] [Technical development guide](https://github.com/NREL/resstock/tree/develop/docs/technical_development_guide)

#### Optional (not all items may apply):
- [ ] Tests (and test files) have been updated
- [ ] Supporting resource files have been updated (related to resstock-estimation)
  - [ ] [data dictionary](https://github.com/NREL/resstock/tree/develop/resources/data/dictionary)
  - [ ] [source report](https://github.com/NREL/resstock/tree/develop/project_national/resources/source_report.csv)
  - [ ] [options saturation](https://github.com/NREL/resstock/tree/develop/project_national/resources/options_saturations.csv)
  - [ ] [options_lookup](https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv)
- [ ] `openstudio tasks.rb update_measures` has been run