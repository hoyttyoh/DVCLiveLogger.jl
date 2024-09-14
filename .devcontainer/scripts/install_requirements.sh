#! /bin/bash

function attempt_install(){
    pip install --user --no-warn-script-location --trusted-host pypi.python.org --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements.txt
}

function update_path(){
    NEW_PATH=${PATH}:/home/vscode/.local/bin
    echo 'export PATH='${NEW_PATH}'' >> /home/vscode/.bashrc
    echo 'export PATH='${NEW_PATH}'' >> /home/vscode/.zshrc
}

if [[ -f "requirements.txt" ]]; 
then
    echo "Found local python project requirements.txt...attempting to install...";
    attempt_install || echo "Could not install python project requirements!";
    update_path || echo "Could not update PATH!";
    exit 0
else
    echo "No python requirements.txt file found."
    exit 0
fi
