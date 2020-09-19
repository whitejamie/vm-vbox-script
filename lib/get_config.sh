#!/bin/bash
# Script that echoes the json value for the input argument json name.
# Usage example:
#     1. vm_hostname=$(get_config "vm_hostname")
#     2. vm_hostname=$(get_config "vm_hostname" -v)
#        
#     -v Verbose, echoes variable name and value to stderr only. Variable value 
#        is still echoed to stdout.
#

function get_config {
    name=$1

    if [[ ! -z "$2" ]] && [[ $2 == "-v" ]]; then
        verbose="True"
    else
        verbose="False"
    fi

    dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

    value=$(jq -e --raw-output .$name $dir/../config.json)

    if [[ $? != 0 ]]; then
        echo 'Invalid vm-config.json name: ' $name
    else
        if [[ $verbose == "True" ]]; then
            echo $name : $value >&2
        fi
        echo $value 
    fi
}