# Ollama LLM  
[Ollama](https://ollama.com/download/linux) is one example source of LLM models. When coupled with Conda and installed in your home directory, you can submit jobs to query a model once running on a job within HTCondor.  
**Please Note: OrangeGrid is not intended for persistent model hosting and not LLM models should be executed on the head/login node**. This example simply downloads a model and performs a basic question/response test.  
Always reference the details on [the Ollama site](https://ollama.com/download/linux) for the latest installation instructions.  

---

## **Installation Steps**  

### **1. Installing Conda**  
For most Python users we recommend installing [Conda](https://docs.conda.io/en/latest/) and
using that to manage your environment if you have not done so alerady. Note that miniforge or miniconda are both acceptable.   

To install Conda:  

```bash
wget https://github.com/conda-forge/miniforge/releases/download/24.7.1-0/Miniforge-pypy3-24.7.1-0-Linux-x86_64.sh

bash Miniforge-pypy3-24.7.1-0-Linux-x86_64.sh  -b -p $HOME/miniforge
eval "$(${HOME}/miniforge/bin/conda shell.bash hook)"

conda init
```

To automatically enable Conda when logging into OrangeGrid, add the following to your ~/.bash_profile:  

```bash
if [ -e ${HOME}/.bashrc ]; then
    source ${HOME}/.bashrc
fi
```

## **2. Installing Ollama**  
To install Ollama in your home directory, use:  

```bash
mkdir -p ~/bin/ollama
cd ~/bin/ollama
curl -L https://ollama.com/download/ollama-linux-amd64.tgz -o ollama-linux-amd64.tgz
tar --no-same-owner --no-same-permissions -xzf ollama-linux-amd64.tgz -C $HOME/bin/ollama
```

Ensure Ollama is executable and update your ~/.bashrc:  

```bash
mv ~/bin/ollama/bin/ollama ~/bin/ollama/
chmod +x ~/bin/ollama/ollama
echo 'export PATH=$HOME/bin/ollama:$PATH' >> ~/.bashrc
echo 'export OLLAMA_MODELS=$HOME/.ollama/models' >> ~/.bashrc
source ~/.bashrc
```

Test that it is installed and working.  

```bash
ollama --version
```

## **3. Downloading a Model**  
Once Ollama is installed, you can download a model for inference. Note the name of the model must be exact. See the [full list](https://ollama.com/search) for details.  
Example:  

```bash
~/bin/ollama/ollama pull deepseek-r1 # Or approprate model name
```

User the list feature to review installed models.  

```bash
~/bin/ollama/ollama list
```

## **4. Setup Your Working Directory**  
This example assumes you'll configure your working home directory location as follows noting that you can deviate but will need to update your submission and wrapper script accordingly.  

```bash
mkdir -p ~/ollama/logs ~/ollama/output ~/ollama/server
```
You can now simply pull the example files and run your demo.  

## **Running the Ollama Example**  
This directory contains a simple Ollama example submissions file that answers a single question after loading an Ollama model. To submit the jobs, be sure to navigate to your Ollama directory where you have put the submission and wrapper script and run the following:  

```bash
condor_submit ollama_demo.sub
```

After submitting, you can check on the progress monitor with:  

```bash
condor_q <your_netid> # check progress
watch -n 5 condor_q <your_netid> # monitor
tail -f ~/ollama/logs/ollama_demo.log # monitor continuously for resource allocation as your model will have several checkpoints of node memory allocation
```

When it complets, you can check the output with:  

```bash
cat ~/ollama/output/ollama_demo.out
```

## **Wrapper Script**  
Note that ollama_demo.sub does not pass the code execution directly. This is because the job needs to be set up so that it will run inside the Conda environment, which is not enabled by default. The submit files therefor calls a wrapper script, which sets up the environment and then runs the Ollama code. For most simple applications you should be able to modify ollama_demo.sh without modifying the submit file.
