#!/bin/bash

eval "$(/home/$( whoami )/miniconda3/bin/conda shell.bash hook)"  
conda activate tfgpu

python3 tensorflow_demo.py

