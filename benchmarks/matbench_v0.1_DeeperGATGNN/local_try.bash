#!/bin/bash
cleanup_tmp_env() {
    # if under `tmp` conda environment, then deactivate it
    if [[ $CONDA_DEFAULT_ENV == "tmp" ]]; then
        conda deactivate
    fi

    # if 'tmp' conda environment exists, then remove it
    if [[ $(conda env list | grep tmp) ]]; then
        conda env remove -n tmp -y
    fi
}

test_import() {
    shopt -s nullglob
    for notebook in *.ipynb; do
        jupyter nbconvert --to script "$notebook"
    done

    # Extract import statements only
    if [[ -f imports_only.py ]]; then
        rm imports_only.py
    fi

    for pyfile in *.py; do
        grep -E "^(import|from .* import)" "$pyfile" >> imports_only.py
    done
    python imports_only.py && echo "All imports are successful" 

    # Clean up
    rm imports_only.py
    for notebook in *.ipynb; do
        rm "${notebook%.ipynb}.py"
    done
}

python_version='3.9'
=========================================================

cleanup_tmp_env

conda create -n tmp python=$python_version -y && conda activate tmp

if [[ $CONDA_DEFAULT_ENV == "tmp" ]]; then
    PACKAGES=$(python -c "import json; print(' '.join(json.load(open('info.json'))['requirements']['python']))")
    echo $PACKAGES
fi
pip install $PACKAGES || conda install $PACKAGES

# remove build tag
PACKAGES_nobuild=$(echo "$PACKAGES" | sed 's/+\([a-zA-Z0-9]*\)//g')
pip install $PACKAGES_nobuild 


PACKAGES_nobuild_0=$(echo "$PACKAGES_nobuild" )
pip install $PACKAGES_nobuild_0

# Create requirements.txt file
echo "$PACKAGES_nobuild_0" | tr ' ' '\n' > requirements_tmp.txt
pip install -r requirements_tmp.txt && rm requirements_tmp.txt


=========================================================

cleanup_tmp_env

conda create -n tmp python=$python_version -y && conda activate tmp

if [[ $CONDA_DEFAULT_ENV == "tmp" ]]; then
    PACKAGES=$(python -c "import json; print(' '.join(json.load(open('info.json'))['requirements']['python']))")
    echo $PACKAGES
fi
PACKAGES_nobuild_0=$(echo "$PACKAGES_nobuild" )
for i in $PACKAGES_nobuild_0; do
    pip install $i
done

=========================================================

cleanup_tmp_env

conda create -n tmp python=$python_version -y && conda activate tmp

if [[ $CONDA_DEFAULT_ENV == "tmp" ]]; then
    PACKAGES=$(python -c "import json; print(' '.join(json.load(open('info.json'))['requirements']['python']))")
    echo $PACKAGES
fi

conda install gxx_linux-64 gcc_linux-64 cmake  -y
conda install pytorch==1.10.0 torchvision==0.11.0 torchaudio==0.10.0 cudatoolkit=11.3 "numpy<2.0" -c pytorch -c conda-forge -y

PACKAGES_nobuild=$(echo "$PACKAGES" | sed 's/+\([a-zA-Z0-9]*\)//g')

for i in $PACKAGES_nobuild; do
    # skip torch
    if [[ $i == torch* ]]; then
        continue
    fi
    pip install $i || break
done
echo $i

