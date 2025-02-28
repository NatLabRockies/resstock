This folder contains the vizualization notebooks used to calibrate and validate the total loads 
and load shapes of Hawaii by county as part of the FY25 ResStock CORE - Hawaii Intergration Task
PI: Janet.Reyna@nrel.gov
Team: Lixi.Liu@nrel.gov, Yingli.Lou@nrel.gov

Before running, set up a virtual environment as follows:
1. Create a virtual environment called `env` inside the resstock repository path and activate the 
environment. This creates a folder called env, which gets git-ignored.
```
cd <path_to_resstock_repo>
python -m venv env
source env/bin/activate
```

2. Install a full installation of [buildstock-query](https://github.com/NREL/buildstock-query), as
well as some packages
```
pip install git+https://github.com/NREL/buildstock-query#egg=buildstock-query
pip install matplotlib openpyxl statsmodels

```

3. For those using VSCode, you may need to install ipykernel
```
pip install ipykernel 
```

4. To deactivate the environment:
```
deactivate
```

5. To delete the virtual environment:
```
rm -rf env
```
