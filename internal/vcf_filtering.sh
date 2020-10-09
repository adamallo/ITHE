#!/bin/bash

if [[ -n "$ITHE_MODULE_SNPSIFT" ]]
then
    if [[ "$ITHE_MOD_ISA" -eq 1 ]]
    then
        if [[ $(module is-avail "$ITHE_MODULE_SNPSIFT") -eq 1 ]]
        then
            module is-loaded "$ITHE_MODULE_SNPSIFT" || module load "$ITHE_MODULE_SNPSIFT"
        else
            echo "ERROR: The module $ITHE_MODULE_SNPSIFT is not available"
            exit 1
        fi
    else
        module load "$ITHE_MODULE_SNPSIFT"
    fi
fi

if [[ -n "$ITHE_EXE_SNPSIFT" ]]
then
    eval "$ITHE_EXE_SNPSIFT"
fi

$ITHE_INT/perl.sh $ITHE_INT/vcf_filtering.pl $@ 
