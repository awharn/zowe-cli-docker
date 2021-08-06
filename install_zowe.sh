#!/bin/bash

# Exit if any commands fail
set -e
PKG_TAG=next

if [ ! -z "$1" ]; then
    ALLOW_PLUGIN_INSTALL_FAIL=$1
fi

# Reload the following - recommended for making nvm available to the script
. ~/.nvm/nvm.sh
. ~/.profile
. ~/.bashrc

# Install the requested version, use the version, and set the default
# for any further terminals

npm config set @zowe:registry https://zowe.jfrog.io/zowe/api/npm/npm-local-release/
rm -rf ~/.zowe/plugins
npm install -g @zowe/cli@${PKG_TAG}

plugins=( @zowe/zos-ftp-for-zowe-cli@${PKG_TAG} @zowe/cics-for-zowe-cli@${PKG_TAG} @zowe/db2-for-zowe-cli@${PKG_TAG} @zowe/ims-for-zowe-cli@${PKG_TAG} @zowe/mq-for-zowe-cli@${PKG_TAG} )

for i in "${plugins[@]}"; do
    if [ ! -z "${ALLOW_PLUGIN_INSTALL_FAIL}" ]; then
        zowe plugins install $i || true
    else
        zowe plugins install $i || exit 1
    fi
done

exit 0
