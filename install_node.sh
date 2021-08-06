#!/bin/bash

# Exit if any commands fail
set -e

# Ensure that a version was passed
if [ -z "$1" ]; then
    echo "No Node.js version supplied for nvm."
else
    NODE_VERSION=$1
    # Reload the following - recommended for making nvm available to the script
    . ~/.nvm/nvm.sh
    . ~/.profile
    . ~/.bashrc

    # Install the requested version, use the version, and set the default
    # for any further terminals
    nvm install $NODE_VERSION
    nvm use --delete-prefix $NODE_VERSION
    nvm alias default $NODE_VERSION
    echo "$NODE_VERSION" > ~/.nvmrc
fi

exit 0



