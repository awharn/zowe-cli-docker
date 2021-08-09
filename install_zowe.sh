#!/bin/bash

# Exit if any commands fail
set -e

if [ ! -z "$1" ]; then
    ALLOW_PLUGIN_INSTALL_FAIL=$1
fi

# Reload the following - recommended for making nvm available to the script
. ~/.nvm/nvm.sh
. ~/.profile
. ~/.bashrc

# Install the requested version, use the version, and set the default
# for any further terminals

rm -rf ~/.zowe/plugins
installDir=/etc/zowe
npm install -g ${installDir}/zowe-cli.tgz

for i in $(find ${installDir} -type f -name "*-zowe-cli.tgz"); do
    if [ ! -z "${ALLOW_PLUGIN_INSTALL_FAIL}" ]; then
        zowe plugins install $i || true
    else
        zowe plugins install $i || exit 1
    fi
done

exit 0
