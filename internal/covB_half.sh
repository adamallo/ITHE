#!/bin/bash

usage="$0 vcf outputvcf bam \n Environment variable GATKJAR should point to GATK\'s jar executable"

if [[ $# -ne 3 ]] || [[ ! -f $1 ]] || [[ ! -f $3 ]]
then
    echo -e $usage
    exit 1
fi

vcf=$1
out=$2
bam=$3

if [[ -n "$ITHE_MODULE_GATK" ]]
then
    if [[ "$ITHE_MOD_ISA" -eq 1 ]]
    then
        if [[ $(module is-avail "$ITHE_MODULE_GATK") -eq 1 ]]
        then
            module is-loaded "$ITHE_MODULE_GATK" || module load "$ITHE_MODULE_GATK"
        else
            echo "ERROR: The module $ITHE_MODULE_GATK is not available"
            exit 1
        fi
    else
        module load "$ITHE_MODULE_GATK"
    fi
        
fi

if [[ -n "$ITHE_EXE_GATK" ]]
then
    eval "$ITHE_EXE_GATK"
fi

if [[ -n "$ITHE_MODULE_BEDOPS" ]]
then
    if [[ "$ITHE_MOD_ISA" -eq 1 ]]
    then
        if [[ $(module is-avail "$ITHE_MODULE_BEDOPS") -eq 1 ]]
        then
            module is-loaded "$ITHE_MODULE_BEDOPS" || module load "$ITHE_MODULE_BEDOPS"
        else
            echo "ERROR: The module $ITHE_MODULE_BEDOPS is not available"
            exit 1
        fi
    else
        module load "$ITHE_MODULE_BEDOPS"
    fi
fi

if [[ -n "$ITHE_EXE_BEDOPS" ]]
then
    eval "$ITHE_EXE_BEDOPS"
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

dothething ()
{
    bam1=$1
    vcf2=$2
    out=$3

    if [[ ! -f $out ]]
    then
        name_vcf2=$(echo $2 | sed "s/.vcf//g")
        name_out=$(echo $out | sed "s/.tsv//g")
        vcf2bed --deletions < $vcf2 > ${name_vcf2}_covB_deletions.bed
        vcf2bed --insertions < $vcf2 > ${name_vcf2}_covB_insertions.bed
        vcf2bed --snvs < $vcf2 > ${name_vcf2}_covB_snvs.bed
        bedops --everything ${name_vcf2}_covB_{deletions,insertions,snvs}.bed | awk 'BEGIN{OFS="\t"}{print($1,$2,$3)}' > ${name_vcf2}_covB.bed
        java -Xms512m -Xmx6G -jar $ITHE_GATKJAR -T UnifiedGenotyper -R $ITHE_HUMAN_GENOME -I $bam1 -o "$name_out.vcf" --intervals ${name_vcf2}_covB.bed --output_mode EMIT_ALL_SITES -glm BOTH -dcov 10000 > "$name_out.log" 2>&1
        cat "$name_out.vcf" | sed "/^#/d" | perl -lane '$F[9]=~s/^[^:]*:([^:]*).*/$1/;@reads=split(",",$F[9]);$reads[1]=="" and $reads[1]=0;if($reads[0] eq "./."){$readsref=0;$readsout=0}else{$readsref=splice(@reads,0,1);$readsout=join(",",@reads)};print join("\t",@F[0,1,3,4],$readsref,$readsout)' > $out
    else
        echo "The file $out is already present and will be reused"
    fi
}

dothething $bam $vcf $out
