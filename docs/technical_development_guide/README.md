# ResStock Technical Development Guide

This folder contains the Read The Docs project for the ResStock Technical Development Guide.

## GitHub Actions
In the `.github/workflows/config.yml` file, the `updates-results` job `Build technical development guide` task compiles the project into the `_build/html` folder.
This folder is then uploaded in the `Save technical development guide` task.
These actions will help keep the document up to date with any changes and fail in the tests if the document does not compile.

## Building Technical Development Guide Locally

### Windows

1. With the terminal/command prompt navigate to the resstock repository technical development guide directory.

```
cd <RESSTOCK_DIR>/docs/technical_development_guide
```

2. Install sphinx Read The Docs theme

```
pip install sphinx_rtd_theme
```

3. Build the documentation. HTML files will be created in the `docs/technical_development_guide/_build` directory

```
./make.bat html SPHINXOPTS="-W --keep-going -n"
```

### Mac

1. With the terminal/command prompt navigate to the resstock repository technical development guide directory.

```
cd <RESSTOCK_DIR>/docs/technical_development_guide
```

2. Install sphinx Read The Docs theme and Sphinx Auto-build

```
pip install sphinx_rtd_theme
pip install sphinx-autobuild
```

3. Build the documentation. HTML files will be created in the `docs/technical_development_guide/_build` directory. 

```
sphinx-autobuild -n -v -w _build/build_errors.txt source/ _build/
```

4. The previous step will connect a server which can be opened in a browser. This server might look something like `http://127.0.0.1:8000`. Copy the address into your browser and the built documentation will show up. The `sphinx-autobuild` command will continue to check for changes to the documentation. So after future changes, the page in the browser should automatically reload to see changes to the source files.
