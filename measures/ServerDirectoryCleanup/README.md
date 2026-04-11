
###### (Automatically generated documentation)

# Server Directory Cleanup

## Description
Optionally removes a significant portion of the saved results from each run, helping to alleviate memory problems.

Present a bunch of bool arguments corresponding to EnergyPlus output files. "False" deletes the file, and "True" retains it. Most arguments default to not retaining the file. Only the in.idf and \*schedules.csv are retained by default.

## Arguments


**Retain in.osm**



- **Name:** ``retain_in_osm``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain in.idf**



- **Name:** ``retain_in_idf``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain pre_process.idf**



- **Name:** ``retain_pre_process_idf``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout.audit**



- **Name:** ``retain_eplusout_audit``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout.bnd**



- **Name:** ``retain_eplusout_bnd``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout.eio**



- **Name:** ``retain_eplusout_eio``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout.end**



- **Name:** ``retain_eplusout_end``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout.err**



- **Name:** ``retain_eplusout_err``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout.eso**



- **Name:** ``retain_eplusout_eso``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout.mdd**



- **Name:** ``retain_eplusout_mdd``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout.mtd**



- **Name:** ``retain_eplusout_mtd``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout.rdd**



- **Name:** ``retain_eplusout_rdd``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout.shd**



- **Name:** ``retain_eplusout_shd``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplusout*.msgpack**



- **Name:** ``retain_eplusout_msgpack``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain eplustbl.htm**



- **Name:** ``retain_eplustbl_htm``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain stdout-energyplus**



- **Name:** ``retain_stdout_energyplus``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain stdout-expandobject**



- **Name:** ``retain_stdout_expandobject``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Retain *schedules.csv**



- **Name:** ``retain_schedules_csv``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Debug Mode?**

If true, retain all files.

- **Name:** ``debug``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>





