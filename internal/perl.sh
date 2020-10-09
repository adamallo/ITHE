#!/bin/bash

if [[ -n "$ITHE_MODULE_PERL" ]]
then
    if [[ "$ITHE_MOD_ISA" -eq 1 ]]
    then
        if [[ $(module is-avail "$ITHE_MODULE_PERL") -eq 1 ]]
        then
            module is-loaded "$ITHE_MODULE_PERL" || module load "$ITHE_MODULE_PERL"
        else
            echo "ERROR: The module $ITHE_MODULE_PERL is not available"
            exit 1
        fi
    else
        module load "$ITHE_MODULE_PERL"
    fi
fi

if [[ -n "$ITHE_EXE_PERL" ]]
then
    eval "$ITHE_EXE_PERL"
fi

perl $@
