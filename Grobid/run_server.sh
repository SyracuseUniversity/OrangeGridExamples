#!/bin/bash

mkdir -p /home/$(whoami)/grobid_tmp

singularity shell -B /home/$(whoami)/grobid_tmp:/opt/grobid/grobid-home/tmp grobid_0.8.2.sif <<EOT
cd /opt/grobid/
grobid-service/bin/grobid-service 
EOT

