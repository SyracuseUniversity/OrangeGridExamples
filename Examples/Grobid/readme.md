# Grobid

## Setup

Download the server

```bash
singularity pull docker://grobid/grobid:0.8.2
```

Note: this won't currently work on the OrangeGrid headnodes.  Building the container requires the intermediate
files be written to `/tmp` and there isn't sufficient space.  For the moment

```bash
cp /home/lppekows/grobid_0.8.2.sif ~
```


Install the client.  Install miniforge or miniconda then run

```bash
eval "$(${HOME}/miniconda3/bin/conda shell.bash hook)"
conda create --name grobid
conda activate grobid
conda install pip
python3 -m pip install grobid-client-python
```

Set up auxilliary files and directories

```bash
wget https://raw.githubusercontent.com/kermitt2/grobid_client_python/refs/heads/master/config.json
mkdir -p pdfin pdfout
```

Download some pdfs into `pdfin`.  You should now be able to

```bash
condor_submit run_grobid.sub
```

---
Please email any questions or comments about this document to Research Computing at [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).

