#!/bin/bash
# Script that echoes the json value for the input argument json name.
# Usage example:
#     echo $(get_config "vm_hostname")

function get_config {
    name=$1

    dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

    value=$(jq -e --raw-output .$name $dir/../config.json)

    if [ $? != 0 ]; then
        echo 'Invalid vm-config.json name: ' $name
    else
        echo $value 
    fi
}