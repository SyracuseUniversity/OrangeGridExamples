#!/usr/bin/env bash

echo $(which apptainer)

apptainer exec haskell_latest.sif ghc seive.hs
apptainer exec haskell_latest.sif seive
