#!/bin/bash

eval "$(/home/$(whoami)/miniforge3/bin/conda shell.bash hook)"
conda activate octave

octave octave_demo.m


