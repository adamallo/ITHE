#!/bin/bash

usage="ITHE Usage:\n-----------\n$0 directory torun_file exe_params filtering_params NAB_params covB_params popAF_params n_cores output_vcf output_list comprehensiveness filterINDELS [queue]\nThis script executes ITHE_control.pl for each sample in a directory with its name. Then it integrates all the information in a file named results.csv and results_basictstv.csv.\nManifest file structure: output N_file A_file B_file [DNA_Quantity]"

queue=""

echo -e "ITHE 0.1\n--------"

##Problems with number of arguments or the user is asking for help

if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]
then
    echo -e $usage
    exit 0
fi

if (! ([[ $# -eq 12 ]] || [[ $# -eq 13 ]]))
then
    echo -e "ERROR: this script needs 12 or 13 arguments, but only $# have been provided.\n\n$usage"
    exit 1
fi

if [[ ! -d $1 ]]
then
    mkdir -p $1
fi

if [[ ! -s $2 ]]
then
    echo -e "ERROR: the manifest file cannot be located. Please, check the information below on how to call this program properly\n\n$usage"
    exit 1
fi

paramfilenames=("exe_params" "filtering_params" "NAB_params" "NAB2_params" "covB_params" "popAF_params")

for ifile in {3..7}
do
    if [[ ! -s ${!ifile} ]]
    then
        thefilename=$(( $ifile - 2 ))
        echo -e "ERROR: the parameter file for ${paramfilenames[!thefilename]}, was specified as ${!ifile} and cannot be located. Please, check the information below on how to call this program properly\n\n$usage"
        exit 1
    fi
done

basedir=$(dirname $0)

if [[ ! -s $basedir/config.txt ]]
then
    echo -e "ERROR: config.txt could not be sourced from $basedir/config.txt. Please, make sure you generate the config.txt file for your system following the installation tutorial in the README\n"
    exit 1
fi

source $basedir/config.txt

##Parsing ARGV
dir=$(readlink -f $1)
torun=$(readlink -f $2)
exe_params=$(readlink -f $3)
filtering_params=$(readlink -f $4)
NAB_params=$(readlink -f $5)
covB_params=$(readlink -f $6)
popAF_params=$(readlink -f $7)
n_cores=$8
output_vcf=${9}
output_list=${10}
comp=${11}
filterINDELS=${12}
queue=${13}

reldir=$(dirname $2)

dependency=""
while read -r output control a b dnac
do
    abscontrol=$(readlink -f $reldir/$control)
    absa=$(readlink -f $reldir/$a)
    absb=$(readlink -f $reldir/$b)

    echo -e "Launching jobs for $output, control file $abscontrol, sampleA file $absa, sampleB file $absb"
    
    filetype=("Control" "SampleA" "SampleB")
    files=($abscontrol $absa $absb)

    for ifile in {1..3}
    do
        if [[ ! -s ${files[!ifile]} ]]
        then
            echo -e "\tERROR: cannot open the file ${files[!ifile]} as the ${filetype[!ifile]} data for $output, according to the manifest file. ITHE will stop submitting jobs. You may want to stop the jobs submitted and empty the output directory before re-running this program. List of jobs already submitted:"
            echo $(echo $dependency | sed "s/${ITHE_ARG_SEP}/ /g")
            exit 1
        fi
    done
    
    if [[ $queue == "" ]]
    then
        id=$($ITHE_INT/perl.sh $ITHE_INT/ITHE_control.pl -e $exe_params -f $filtering_params --NABfilt_cond_inputfile $NAB_params --covaltB_cond_inputfile $covB_params --popAF_cond_inputfile $popAF_params -o $dir/${output}.csv --normal_bamfile $abscontrol --sample_A_bamfile $absa --sample_B_bamfile $absb --output_dir $dir/$output --n_cores $n_cores --output_vcf $output_vcf --output_list $output_list --comp $comp --filterINDELS $filterINDELS | tee $dir/${output}.out | tail -n 1)
    else
        id=$($ITHE_INT/perl.sh $ITHE_INT/ITHE_control.pl -e $exe_params -f $filtering_params --NABfilt_cond_inputfile $NAB_params --covaltB_cond_inputfile $covB_params --popAF_cond_inputfile $popAF_params -o $dir/${output}.csv --normal_bamfile $abscontrol --sample_A_bamfile $absa --sample_B_bamfile $absb --output_dir $dir/$output --n_cores $n_cores --output_vcf $output_vcf --output_list $output_list --comp $comp --queue $queue --filterINDELS $filterINDELS | tee $dir/${output}.out | tail -n 1) 
    fi
    dependency="${dependency}${ITHE_ARG_SEP}${id}"
done < $torun

tstv=1

if [[ $comp -ne 2 ]] || [[ ${9} == 0 ]]
then
    tstv=0
fi

if [[ $queue == "" ]]
then
    $ITHE_SUBMIT_CMD ${ITHE_ARG_DEP}$dependency $ITHE_MAX_MEM $ITHE_INT/summarizeResults.sh $dir $torun $exe_params $filtering_params $NAB_params $NAB2_params $covB_params $popAF_params $n_cores $tstv
else
    $ITHE_SUBMIT_CMD ${ITHE_SUBMIT_PAR}$queue ${ITHE_ARG_DEP}$dependency $ITHE_MAX_MEM $ITHE_INT/summarizeResults.sh $dir $torun $exe_params $filtering_params $NAB_params $NAB2_params $covB_params $popAF_params $n_cores $tstv
fi
