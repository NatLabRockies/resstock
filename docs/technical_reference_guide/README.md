# ResStock Technical Reference Guide

This folder contains the LaTeX project for the ResStock Technical Reference Guide.
The main file is the `ResStockTechnicalReferenceGuide.tex` file and when compiled produces `ResStockTechnicalReferenceGuide.pdf` in this directory. 

## GitHub Actions
In the `.github/workflows/config.yml` file, the `updates-results` job `Build technical reference guide` task compiles the project into the `ResStockTechnicalReferenceGuide.pdf` file.
This file is then committed in the "Latest results" commit in the `Commit latest results` task.
These actions will help keep the document up to date with any changes and fail in the tests if the document does not compile.

## Building Technical Reference Guide Locally
Docker can be used to compile the ResStock Technical Reference Guide locally. First install [Docker](https://www.docker.com/) and follow the steps below.

1. With the terminal/command prompt navigate to the resstock repository technical reference guide directory.

```
cd <RESSTOCK_DIR>/docs/technical_reference_guide
```

2. Pull a docker container with the full version of textlive (this might take several minutes, but only needs to be done once. If you have issues, get off the VPN during the pull)

```
$ docker pull mfisherman/texlive-full
```

3. Run the container and mount the current directory contents in the workspace directory of the container. Use /bin/bash as the default shell.

```
docker run --rm -it -v $(pwd):/workspace mfisherman/texlive-full /bin/bash
```

4. The container should start running immediately. Once in the container, your CLI looks something like this: `19603f1794b0:/data#`, with `19603f1794b0` likely being different. Go to the workspace folder where the Technical Reference Guide directory is located.

```
cd ../workspace
```

5. Create a _build directory for the output of `pdflatex` to be stored.
```
mkdir _build
```

6. Compile the documentation (this command may need to be run two times for some parts of the documentation to show up in the output pdf)

```
latexmk -pdf -latexoption=-file-line-error -latexoption=-interaction=nonstopmode -output-directory=_build -halt-on-error ResStockTechnicalReferenceGuide.tex 
```

7. All of the pdf and log files from the compile will be located in docs/technical_reference_guide/_build (Note: this won't show up as modified files in git because _build is in .gitignore)

8. If the pdf does not compile successfully, look for fatal errors in the .log file, apply fixes, and recompile as needed by repeating step 5. To stop the workflow and exit out of the container, type exit in the CLI or hit Ctrl + D on your keyword.

