# Zowe CLI Docker Container

This repository contains the files required to create a Zowe CLI docker container

To run the container, run `docker run -it -u zowe --cap-add=IPC_LOCK awharn/zowe-cli:next-20210726 /bin/bash`

Requirements:

- IPC_LOCK capability - Secure credential storage
- Access to the internet (for updating NPM version - does not apply if NODE_JS_NVM_VERSION is unset)

Environment variables:

- NODE_JS_NVM_VERSION - Uses NVM to change the version of NPM for the `zowe` user
- ALLOW_PLUGIN_INSTALL_FAIL - Allows plugin installation to fail in the entrypoint without stopping the container if set