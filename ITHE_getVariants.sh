#!/bin/bash

usage="\n$0 main_results_directory output_file.tsv\nThis script outputs a tsv file with all variants and some statistical information\n"

if [[ $# -ne 2 ]] || [[ ! -d $1 ]]
then
    echo -e $usage
    exit 1
fi

basedir=$(dirname $0)

if [[ ! -s $basedir/config.txt ]]
then
    echo -e "ERROR: config.txt could not be sourced from $basedir/config.txt. Please, make sure you generate the config.txt file for your system following the installation tutorial in the README\n"
    exit 1
fi

source $basedir/config.txt

dir=$1
outvariants=$2

if [[ $queue == "" ]]
then
    id=$($ITHE_SUBMIT_CMD $ITHE_INT/perl.sh $ITHE_INT/tabulate_annovar.pl -d $dir -o ${outvariants}_tmp --covB covB --paf PAF | eval $ITHE_SUBMIT_SED)
else
    id=$($ITHE_SUBMIT_CMD ${ITHE_SUBMIT_PAR}$queue $ITHE_INT/perl.sh $ITHE_INT/tabulate_annovar.pl -d $dir -o ${outvariants}_tmp --covB covB --paf PAF | eval $ITHE_SUBMIT_SED)
fi
dependency="${ITHE_ARG_DEP}${ITHE_ARG_SEP}${id}"

if [[ $queue == "" ]]
then
    $ITHE_SUBMIT_CMD $dependency $ITHE_INT/perl.sh $ITHE_INT/addNRNVtabulate_1col.pl -f $dir -r -i ${outvariants}_tmp -o ${outvariants} -s filtcovBNABPAF
else
    $ITHE_SUBMIT_CMD ${ITHE_SUBMIT_PAR}$queue $dependency $ITHE_INT/perl.sh $ITHE_INT/addNRNVtabulate_1col.pl -f $dir -r -i ${outvariants}_tmp -o ${outvariants} -s filtcovBNABPAF
fi

