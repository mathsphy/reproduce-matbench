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

conda env create -f environment.yml -n tmp -y && conda activate tmp # successfully created the environment

test_import # this fails with ModuleNotFoundError: No module named 'matbench'

pip install matbench # fails with the following error

: "
ERROR: pip's dependency resolver does not currently take into account all the packages that are installed. This behaviour is the source of the following dependency conflicts.
auto-sklearn 0.15.0 requires scikit-learn<0.25.0,>=0.24.0, but you have scikit-learn 1.0.1 which is incompatible. 
"

test_import # but this works fine

# run notebook.ipynb
jupyter nbconvert --to notebook --execute notebook.ipynb # this gives `TypeError: unhashable type: 'list'`


================= Read from info.json ========================

cleanup_tmp_env
conda create -n tmp python=$python_version -y && conda activate tmp
if [[ $CONDA_DEFAULT_ENV == "tmp" ]]; then
    PACKAGES=$(python -c "import json; print(' '.join(json.load(open('info.json'))['requirements']['python']))")
    echo $PACKAGES
fi

pip install matbench # we know from the previous step that this is missing
pip install $PACKAGES # this fails
conda install $PACKAGES -y # this works 

test_import # this works 

jupyter nbconvert --to notebook --execute notebook.ipynb # 
: "
ValueError: (' Dummy prediction failed with run state StatusType.CRASHED and additional output: {\'error\': \'Result queue is empty\', \'exit_status\': "<class \'pynisher.limit_function_call.AnythingException\'>", \'subprocess_stdout\': \'\', \'subprocess_stderr\': \'Process pynisher function call:\\nTraceback (most recent call last):\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/multiprocessing/process.py", line 315, in _bootstrap\\n    self.run()\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/multiprocessing/process.py", line 108, in run\\n    self._target(*self._args, **self._kwargs)\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/site-packages/pynisher/limit_function_call.py", line 133, in subprocess_func\\n    return_value = ((func(*args, **kwargs), 0))\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/site-packages/autosklearn/evaluation/__init__.py", line 55, in fit_predict_try_except_decorator\\n    return ta(queue=queue, **kwargs)\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/site-packages/autosklearn/evaluation/train_evaluator.py", line 1386, in eval_cv\\n    evaluator = TrainEvaluator(\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/site-packages/autosklearn/evaluation/train_evaluator.py", line 206, in __init__\\n    super().__init__(\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/site-packages/autosklearn/evaluation/abstract_evaluator.py", line 215, in __init__\\n    threadpool_limits(limits=1)\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/site-packages/threadpoolctl.py", line 794, in __init__\\n    super().__init__(ThreadpoolController(), limits=limits, user_api=user_api)\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/site-packages/threadpoolctl.py", line 587, in __init__\\n    self._set_threadpool_limits()\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/site-packages/threadpoolctl.py", line 720, in _set_threadpool_limits\\n    lib_controller.set_num_threads(num_threads)\\n  File "/home/kangming/miniconda3/envs/tmp/lib/python3.9/site-packages/threadpoolctl.py", line 199, in set_num_threads\\n    return set_num_threads_func(num_threads)\\nKeyboardInterrupt\\n\', \'exitcode\': 1, \'configuration_origin\': \'DUMMY\'}.',)
"



================= Read from info.json, use only conda  ========================

cleanup_tmp_env
conda create -n tmp python=$python_version -y && conda activate tmp
if [[ $CONDA_DEFAULT_ENV == "tmp" ]]; then
    PACKAGES=$(python -c "import json; print(' '.join(json.load(open('info.json'))['requirements']['python']))")
    echo $PACKAGES
fi

conda install matbench -y 
conda install $PACKAGES -y # this does not work 

================= 
cleanup_tmp_env

conda create -n tmp python=$python_version -y && conda activate tmp
pip install matbench swig==4.1.0 auto-sklearn==0.15.0 'numpy<2' jupyter

sed -e 's/results.json.gz/new_results.json.gz/g' notebook.ipynb > tmp.ipynb && jupyter nbconvert --to notebook --execute tmp.ipynb # this gives `TypeError: unhashable type: 'list'`
rm tmp.ipynb
