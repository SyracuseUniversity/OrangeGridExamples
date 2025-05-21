#!/bin/bash

/usr/local/bin/singularity exec --nv ollama_latest.sif /bin/bash <<EOT
cd $PWD
ollama serve > output/serve.out 2>&1 &
SERVE_PID=\$!
sleep 10

ollama run llama2 < input/prompt.txt

# HTCondor will do this if we don't, but it's polite to clean up
kill -9 \$SERVE_PID
EOT


