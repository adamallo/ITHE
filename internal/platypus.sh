#!/bin/bash

if [[ -n "$ITHE_MODULE_PLATYPUS" ]]
then
    if [[ "$ITHE_MOD_ISA" -eq 1 ]]
    then
        if [[ $(module is-avail "$ITHE_MODULE_PLATYPUS") -eq 1 ]]
        then
            module is-loaded "$ITHE_MODULE_PLATYPUS" || module load "$ITHE_MODULE_PLATYPUS"
        else
            echo "ERROR: The module $ITHE_MODULE_PLATYPUS is not available"
            exit 1
        fi
    else
        module load "$ITHE_MODULE_PLATYPUS"
    fi
fi

if [[ -n "$ITHE_EXE_PLATYPUS" ]]
then
    eval "$ITHE_EXE_PLATYPUS"
fi

if [[ -z "$ITHE_HUMAN_GENOME" ]]
then
    echo "ERROR: The environment variable ITHE_HUMAN_GENOME needs to point to the fasta file with the human reference genome\n";
    exit 1
else
    if [[ ! -f "$ITHE_HUMAN_GENOME" ]]
    then
        echo "ERROR: The environment variable ITHE_HUMAN_GENOME is not set properly\n"
        exit 1
    fi
fi

bamfiles=$1
output=$2
logfilename=$3
filterINDELS=$4

if [[ ! -s ${bamfiles}.bai ]]
then
    if [[ ! -s $bamfiles ]]
    then
        echo -e "ERROR: the file $bamfiles cannot be found\n"
    else
        echo -e "WARNING: the file $bamfiles is not indexed. ITHE will try to use samtools to index it before running platypus\n"
        
        ##SAMTOOLS ENVIRONMENT
        if [[ -n "$ITHE_MODULE_SAMTOOLS" ]]
        then
            if [[ "$ITHE_MOD_ISA" -eq 1 ]]
            then
                if [[ $(module is-avail "$ITHE_MODULE_SAMTOOLS") -eq 1 ]]
                then
                    module is-loaded "$ITHE_MODULE_SAMTOOLS" || module load "$ITHE_MODULE_SAMTOOLS"
                else
                    echo "ERROR: The module $ITHE_MODULE_SAMTOOLS is not available"
                    exit 1
                fi
            else
                module load "$ITHE_MODULE_SAMTOOLS"
            fi
        fi
        
        if [[ -n "$ITHE_EXE_SAMTOOLS" ]]
        then
            eval "$ITHE_EXE_SAMTOOLS"
        fi
        ###
    
        samtools index $bamfiles
    fi
fi

if [[ $# -ge 4 ]]
then
    shift 4
    platypus callVariants --nCPU=${!ITHE_NCPUS_VAR} --bamFiles=$bamfiles --refFile=${ITHE_HUMAN_GENOME} --output=$output --logFileName=$logfilename $@ 
else
    echo "Error, the number of arguments for this script is not appropriate"
fi

mv $output ${output}_bkp_multisnv
$ITHE_INT/perl.sh $ITHE_INT/separateMultipleSNVPlatypus.pl -i ${output}_bkp_multisnv -o $output -f $filterINDELS
