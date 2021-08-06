#!/bin/bash

#########################################################
# Setup ENTRYPOINT script when running the image:       #
# - Installs Zowe CLI and plugins for root              #
# - Installs Zowe CLI and plugins for zowe           #
#########################################################

# Exit if any commands fail
set -e

# Do the original entrypoint
# Extract Node.js version from env var
VERSION=$NODE_JS_NVM_VERSION
APIF=$ALLOW_PLUGIN_INSTALL_FAIL

if [ -z "$VERSION" ]; then
    echo "No version specified"
else
    # Execute the node installation script
    echo "Installing Node.js version $VERSION for current user..."
    install_node.sh $VERSION

    # Execute the script for user zowe
    echo "Installing Node.js version $VERSION for zowe user..."
    su -c "install_node.sh $VERSION" - zowe

    # Do the install for zowe
    su -c "install_zowe.sh $APIF" - zowe
fi

# Execute passed cmd
exec "$@"
