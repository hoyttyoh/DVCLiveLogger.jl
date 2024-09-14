# Runs after the Docker container is first built.
# configure pip
echo -e "Updating pip global configs to avoid trust issues."

mkdir -p /home/vscode/.config/pip && touch /home/vscode/.config/pip/pip.conf

pip config set global.trusted-host pypi.python.org
pip config set global.trusted-host pypi.org
pip config set global.trusted-host files.pythonhosted.org

# install python dev requirements
echo -e "Installing a few additional python packages..."
pip install -r .devcontainer/dev-requirements.txt

# install Julia using Juliaup
echo -e "Installing Julia ${JULIA_VERSION}...\n"
curl -fsSL https://install.julialang.org | sh -s -- --yes --default-channel ${JULIA_VERSION}

echo "Adding packages for development..."
echo '/home/vscode/.juliaup/bin/julia .devcontainer/scripts/julia_dev_pkgs.jl' | sh


echo "Adding workspace project folder to PATH."; 
cat .devcontainer/scripts/update_path.sh >> /home/vscode/.bashrc
    
