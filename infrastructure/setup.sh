#! /usr/bin/env bash

sudo mkdir -p /etc/nca
export NICE_APP_DEVICE="/dev/xvdc"
export NICE_APP_MOUNTPOINT="/opt"
export NICE_SWAP_DEVICE="/dev/xvdf"
sudo curl -o /etc/nca/bootstrap-azure.sh https://shddevuse01sa01.blob.core.windows.net/global-package-repos-use1/terraform/user_data/os_base/azure/bootstrap-azure.sh
# /bin/bash /etc/nca/bootstrap-azure.sh -f=${local.rts_hostnames[count.index]}.use1.devops.lab 2>&1 | tee /etc/nca/bootstrap.log