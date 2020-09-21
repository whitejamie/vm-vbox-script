#!/bin/bash
# Script that echoes the json value for the input argument json name.
# Usage example:
#     1. vm_hostname=$(get-config CONFIG_JSON JSON_KEY)
#     2. vm_hostname=$(get-config CONFIG_JSON JSON_KEY -v)
#       
#  CONFIG_JSON : Path to .json configuration file.
#
#  JSON_KEY    : .json key name to use to return value, e.g. "vm_hostname"
#
#  -v Verbose, echoes variable name and value to stderr only. Variable value 
#        is still echoed to stdout.
#

function get-config {
    config_json=$1
    name=$2

    if [[ ! -z "$3" ]] && [[ $3 == "-v" ]]; then
        verbose="True"
    else
        verbose="False"
    fi

    value=$(jq -e --raw-output .$name $config_json)

    if [[ $? != 0 ]]; then
        echo 'Invalid vm-config.json name: ' $name
    else
        if [[ $verbose == "True" ]]; then
            echo $name : $value >&2
        fi
        echo $value 
    fi
}