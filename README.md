# IntraTumor Heterogeneity Estimator (ITHE)
ITHE implementes a somatic variant post-processing pipeline using a system of perl and bash scripts. ITHE can be used to call SNV variants and estimate the intratumor heterogeneity between two samples per individual given a set of user-specified parameters, and to perform the empirical optimization of those parameters using technical replicates (same DNA sample sequenced twice independently). ITHE is intended to be run on a HPC environment, interacting directly with a workload manager that supports dependencies between jobs. We developed ITHE on a SLURM environment, but it should be easy to configure to run under other workload managers of similar characteristics.

# Installation
We developed ITHE to run on a Linux environment, and have only tested it in such kind of environment for now.
Once dependencies are resolved, the instalation of ITHE only requires downloading the source code and configuring it to run on the user's HPC environment, either manually or using a helper script included in the repository, configAssistant.pl. 

## Dependencies
The following programs and libraries need to be available in the HPC system. ITHE provides a way of loading modules and executing code before any of the programs are executed, increasing its flexibility. These commands need to make sure the executable of each program is in the PATH at execution time. This can be configured manually editing the config.txt file, or running the helper script configAssistant.pl.

### Programs
- Annovar
- Platypus
- vcftools
- GNU parallel
- GATK with UnifiedGenotyper
- BEDOPS 
- SNPSIFT
- Samtools (Only if the bam files are not indexed)

#### Other programs that should be available within your Linux environment
- BASH
- AWK
- readlink
- Perl

### Perl libraries:
- Getopt::Long
- Cwd
- File::Basename
- Env
- Sort::Key::Maker
- Sort::Key::Natural
- Bio::DB::HTS::Tabix 
- Parallel::Loops (Only for fine-grain parallelization)
- File::Copy

*NOTE*: If using a HPC system without administrative privileges, these can be installed in a local perl library and load using Mlocal::lib in the perl configurable executable file.

## Configuration
### configAssistant.pl
TBD
### Exhaustive list of ITHE Environment variables
#### Required variables
These variables are necessary to indicate the location of different components of the pipeline.
- *ITHE_HOME*: Directory that contains ITHE repository, where ITHE_loop.sh is located.
- *ITHE_INT*: Directory where internal ITHE scripts are located, typically, $ITHE_HOME/internal
- *ITHE_HUMANDB_DIR*: Directory where annovar stores its reference genome
- *ITHE_HUMAN_GENOME*: Human reference genome fasta file
- *ITHE_GNOMAD*: GNOMAD Population allele frequency information (see XX for instructions on how to generate this file).

#### Modules
These variables indicate the name of the module that must be loaded before the execution of the program with the same name.
- ITHE_MODULE_PERL
- ITHE_MODULE_ANNOVAR
- ITHE_MODULE_PLATYPUS
- ITHE_MODULE_VCFTOOLS
- ITHE_MODULE_GNUPARALLEL
- ITHE_MODULE_GATK
- ITHE_MODULE_BEDOPS
- ITHE_MODULE_SNPSIFT
- ITHE_MODULE_SAMTOOLS

#### Exes
The string contained on these variables are executed using eval before the execution of the program with the same name. To be used if needed.
- ITHE_EXE_PERL
- ITHE_EXE_ANNOVAR
- ITHE_EXE_PLATYPUS
- ITHE_EXE_VCFTOOLS
- ITHE_EXE_GNUPARALLEL
- ITHE_EXE_GATK
- ITHE_EXE_BEDOPS
- ITHE_EXE_SNPSIFT
- ITHE_EXE_SAMTOOLS

#### Workload manager environment variables
- *ITHE_NCPUS_VAR*: Must contain the name of the environment variable that indicates the number of CPU threads available for a specific job
- *ITHE_SUBMIT_CMD*: Command to submit a job. For example, "sbatch" for SLURM
- *ITHE_SUBMIT_SED*: Command that when executed and piped the job submission command returns the ID of the job
- *ITHE_SUBMIT_MUL*: Arguments to add to ITHE_SUBMIT_CMD, except the number of threads, which will be appended automatically, when submitting a multithreaded job. For example, "-N 1 -n 1 -c " for SLURM
- *ITHE_SUBMIT_PAR*: Argument to indicate the queue/partition a job should be submitted to. For example, "--partition=" for SLURM 
- *ITHE_ARG_DEP*: Argument to indicate the dependencies of a job when it is submitted. For example, "--dependency=afterok" for SLURM (or a different condition)
- *ITHE_ARG_SEP*: Argument that separates job_ids when indicating dependencies, ":" for SLURM.
- *ITHE_MAX_TIME*: Argument to indicate the maximum time that can be allocated to a job. This will only be used for time-consuming steps of the pipeline. We recomend to set this parameter only if the user will be using ITHE to carry out parameter optimization. Example, "-t 4-00:00" to allocate four days in SLURM.
- *ITHE_MAX_MEM*: Argument to indicate the maximum memory that can be allocated by a job. This will only be used by memory-intensive steps of the pipeline. We recomend to set this parameter only if the user will be using ITHE to carry out parameter optimization. Example, "--mem=16G" to allocate 16GB of RAM in SLURM. More than 16GB should not be needed.

#### System variables
- *ITHE_MOD_ISA*: This indicates if your version of Environment Modules supports the is-available command or not. ITHE will work either way, but will use that more advanced command if available.

## Accesory data preparation
### gnomAD
ITHE uses [gnomAD](https://gnomad.broadinstitute.org/) population allele frequency estimates. The [complete gnomad genomic VCF file is almost 500GB](https://storage.googleapis.com/gnomad-public/release/2.1.1/vcf/genomes/gnomad.genomes.r2.1.1.sites.vcf.bgz), so we recommend to thin it keeping only the needed information for ITHE using the following commands:
```bash
gunzip -c gnomad.genomes.r2.1.sites.vcf.bgz | head -n 1000 | grep '^# ' > gnomad.genomes.r2.1.sites.onlyAFINFO.vcf
gunzip -c gnomad.genomes.r2.1.sites.vcf.bgz | perl -pe 's/\t[^\t]*;(AF=[^;]+).*$/\t$1/' >> gnomad.genomes.r2.1.sites.onlyAFINFO.vcf
```
# Usage
The main ITHE executable script is ITHE_loop.sh. This program submits a series of jobs to call variants using platypus on trios of samples from a patient, two somatic samples (usually neoplastic tissue) and one control sample to estimate the germline genotype of the patient, filters them using ITHE's pipeline, and calculates the heterogeneity between the samples. ITHE_loop.sh uses a space-separated manifest file with the following structure `Sample Normal_file SampleA_file SampleB_file [DNA]` and as many rows as patients. The filtering options are used specified, and if several options are provided, ITHE performs this process using all possible combinations of them. Following, the user specifies the number of cpu threads to request for multi-threaded jobs, binary flags for vcf output, list of variants output, output verbosity, and to filter out indels.

Example for parameter optimization using 8 cpu threads per parallel job, without any variant output (only the optimization summary), including indels. **WARNING**: it is not recomended to activate variant ouptut when using ITHE for optimization, due to the volume of output files (and IO operations).
```
../ITHE_loop.sh out manifest.txt params/exe_params params/filtering_params params/NAB_params params/covB_params params/PAF_params 8 0 0 0 0
```

Example for variant calling using 8 cpu threads per parallel job, with all the outputs with maximum output verbosity (all intermediate vcf files), only attending to SNVs:
```
../ITHE_loop.sh out manifest.txt params/exe_params params/filtering_params params/NAB_params params/covB_params params/PAF_params 8 1 1 2 1
```

To obtain the final list of variants after all ITHE jobs have finished, execute the ITHE_getVariants.sh, indicating the folder with ITHE results and the output file name. This can only be done when ITHE has run with output verbosity=2 and vcf output activated.

```
../ITHE_getVariants.sh out/ variants.tsv
```

## ITHE parameters
Six groups of parameters control ITHE's execution, each specified in a different input file, following the format `parameter-name,value1,value2,valuen`. Example parameter files can be found in the example directory within the repository and are explained below.

### Variant-calling parameters (exe_params)
These parameters are directly passed to the variant calling software, Platypus in this version of the pipeline.
Example:
```
--filterReadPairsWithSmallInserts=,0
--minReads=,3
```

### Variant filtering parameters (filtering_params)
These parameters are used to filter the variants to generate the stringent variant set. Currently, the supported options are:
- -q/--qual : min quality filter
- --atoc : filter out mutations from A to C
- --atog : filter out mutations from A to G
- --atot : filter out mutations from A to T
- --ctoa : filter out mutations from C to A
- --ctog : filter out mutations from C to G
- --ctot : filter out mutations from C to T
- --gtoa : filter out mutations from G to A
- --gtoc : filter out mutations from G to C
- --gtot : filter out mutations from G to T
- --ttoa : filter out mutations from T to A
- --ttoc : filter out mutations from T to C
- --ttog : filter out mutations from T to G
- -m/--min_coverage : minimum coverage per locus
- --max_coverage: maximum coverage per locus
- -s/--min_reads_strand : minimum number of reads per strand
- -a/--min_reads_alternate : minimum number of reads for the alternative allele
- --max_reads_alternate : maximum number of reads for the alternative allele
- --min_freq_alt : min frequency of reads supporting the alternative allele

Example:
```
--qual,120
--min_coverage,0
--min_reads_strand,15
--min_reads_alternate,0
 ```

### Position filtering parameters 2: Control (NAB_params)
These parameters are used to filter somatic variants, based on information of that genomic position in the control sample. Currently, the supported filters are:

- --min_coverage : minimum coverage per locus
- --max_alternative : maximum number of reads supporting an alternative allele
- --max_propalt : maximum proportion of reads supporting an alternative allele

Example:
```
--min_coverage,20
--max_alternative,-1
--max_propalt,0.10
```
**NOTE**: The -1 value deactivates a filter.
**WARNING**: max_alternative and max_propralt here work differently than in covB_params, having to both be met in order to discard a variant.

### Position filtering parameters 1: B sample (covB_params)
These parameters are used to filter out variants detected as private in sample A, based on information of that genomic position in sample B. Currently, the supported filters are:

- --min_coverage : minimum coverage per locus
- --max_alternative : maximum number of reads supporting an alternative allele
- --max_propalt : maximum proportion of reads supporting an alternative allele

Example:
```
--min_coverage,15
--max_alternative,0
--max_propalt,0.05
```

### Population allele frequency parameters (PAF_params)
These parameters are used to filter out variants based on information of their population allele frequency. Currently, the supported filters are:

- --max_pAF: maximum population allele frequency for a variant to be kept.

Example:
```
--max_pAF,0.25
```

## Output
### Statistics and optimization
The main output of ITHE_loop.sh is the results.csv file. This comma-separated file contains a large number of statistics at different stages of the pipeline for each case and combination of parameter values. The final similarity can be found in the filtNABcovBPAF_propU column.
### Variants
The final list of variants can be obtained using the ITHE_getVariants.sh command, as explained above.

# Citation
Fortunato A\*, Mallo D\*, et al. (submitted) A new method to accurately identify single nucleotide variants using small FFPE breast samples

