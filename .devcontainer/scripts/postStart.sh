# Runs everytime the Docker container is started.

wrk_dir=/workspaces/${PROJECT_FOLDER}
src_dir=${wrk_dir}/src
python_path='export PYTHONPATH='${src_dir}':'${wrk_dir}'${PYTHONPATH:+:${PYTHONPATH}'
path='export PATH='${src_dir}':'${wrk_dir}'${PATH:+:${PATH}'

export PIP_DEFAULT_TIMEOUT=100
if [[ -f "requirements.txt" ]]; 
then
    echo "Found local python project requirements.txt...attempting to install...";
    pip install -r requirements.txt
else
    echo "No python requirements.txt file found."
fi

echo "Make sure vscode user is in docker group..."
sudo usermod -aG docker $USERNAME



