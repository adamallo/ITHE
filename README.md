# IntraTumor Heterogeneity Estimator (ITHE)
ITHE implementes a somatic variant post-processing pipeline using a system of perl and bash scripts. ITHE can be used to call SNV variants and estimate the intratumor heterogeneity between two samples per individual given a set of user-specified parameters, and to perform the empirical optimization of those parameters using technical replicates (same DNA sample sequenced twice independently). ITHE is intended to be run on a HPC environment, interacting directly with a workload manager that supports dependencies between jobs. We developed ITHE on a SLURM environment, but it should be easy to configure to run under other workload managers of similar characteristics.

# Installation
We developed ITHE to run on a Linux environment, and have only tested it in such kind of environment for now.
Once dependencies are resolved, the instalation of ITHE only requires downloading the source code and configuring it to run on the user's HPC environment, either manually or using a helper script included in the repository, configAssistant.pl. 

## Dependencies
The following programs and libraries need to be available in the HPC system. ITHE provides a way of loading modules and executing code before any of the programs are executed, increasing its flexibility. These commands need to make sure the executable of each program is in the PATH at execution time. This can be configured manually editing the config.txt file, or running the helper script configAssistant.pl.

###Programs
- Annovar
- Platypus
- vcftools
- GNU parallel
- GATK with UnifiedGenotyper
- BEDOPS 
- SNPSIFT
- Samtools (Only if the bam files are not indexed)

####Other programs that should be available within your Linux environment
- BASH
- AWK
- readlink
- Perl

###Perl libraries:
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
#Required variables
These variables are necessary to indicate the location of different components of the pipeline.
- ITHE_HOME: Directory that contains ITHE repository, where ITHE_loop.sh is located.
- ITHE_INT: Directory where internal ITHE scripts are located, typically, $ITHE_HOME/internal
- ITHE_HUMANDB_DIR: Directory where annovar stores its reference genome
- ITHE_HUMAN_GENOME: Human reference genome fasta file
- ITHE_GNOMAD: GNOMAD Population allele frequency information (see XX for instructions on how to generate this file).

####Modules
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

#Exes
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

#Workload manager environment variables
- ITHE_NCPUS_VAR: Must contain the name of the environment variable that indicates the number of CPU threads available for a specific job
- ITHE_SUBMIT_CMD: Command to submit a job. For example, "sbatch" for SLURM
- ITHE_SUBMIT_SED: Command that when executed and piped the job submission command returns the ID of the job
- ITHE_SUBMIT_MUL: Arguments to add to ITHE_SUBMIT_CMD, except the number of threads, which will be appended automatically, when submitting a multithreaded job. For example, "-N 1 -n 1 -c " for SLURM
- ITHE_SUBMIT_PAR: Argument to indicate the queue/partition a job should be submitted to. For example, "--partition=" for SLURM 
- ITHE_ARG_DEP: Argument to indicate the dependencies of a job when it is submitted. For example, "--dependency=afterok" for SLURM (or a different condition)
- ITHE_ARG_SEP: Argument that separates job_ids when indicating dependencies, ":" for SLURM.
- ITHE_MAX_TIME: Argument to indicate the maximum time that can be allocated to a job. This will only be used for time-consuming steps of the pipeline. We recomend to set this parameter only if the user will be using ITHE to carry out parameter optimization. Example, "-t 4-00:00" to allocate four days in SLURM.
- ITHE_MAX_MEM: Argument to indicate the maximum memory that can be allocated by a job. This will only be used by memory-intensive steps of the pipeline. We recomend to set this parameter only if the user will be using ITHE to carry out parameter optimization. Example, "--mem=16G" to allocate 16GB of RAM in SLURM. More than 16GB should not be needed.

#System variables
- ITHE_MOD_ISA: This indicates if your version of Environment Modules supports the is-available command or not. ITHE will work either way, but will use that more advanced command if available.

### Environment variables
- SCRIPTSVCF_DIR to indicate the directory where they are located
- SUBMITCMD: contains the command to submit jobs to the cluster. Default="sbatch"
- GNOMAD to indicate the tabix VCF file of gnomAD

##Accesory data preparation
###gnomAD

gunzip -c gnomad.genomes.r2.1.sites.vcf.bgz | head -n 1000 | grep '^#' > gnomad.genomes.r2.1.sites.onlyAFINFO.vcf
gunzip -c gnomad.genomes.r2.1.sites.vcf.bgz | perl -pe 's/\t[^\t]*;(AF=[^;]+).*$/\t$1/' >> gnomad.genomes.r2.1.sites.onlyAFINFO.vcf

# Usage



#Citation
Fortunato A\*, Mallo D\*, et al. (submitted) A new method to accurately identify single nucleotide variants using small FFPE breast samples

