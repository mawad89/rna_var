#GATK_1.sh

#!/bin/sh -login
#PBS -l nodes=1:ppn=4,mem=64gb,walltime=4:00:00
#PBS -M hussien@msu.edu
#PBS -m abe

data_path=$"/mnt/ls15/scratch/users/hussien/RNA_VAR_NEW/data/"
script_path=$"/mnt/ls15/scratch/users/hussien/RNA_VAR_NEW/scripts/"
out_path=$"/mnt/ls15/scratch/users/hussien/RNA_VAR_NEW/output/"
genome_path=$"/mnt/ls15/scratch/users/hussien/RNA_VAR_NEW/genomeDir/"

module load Java/1.8.0_31
module load GATK
java -Xmx10g -cp $GATK -jar $GATK/GenomeAnalysisTK.jar -T SplitNCigarReads -R ${genome_path}/GATK_indexed/GRCh38_r77.all.fa -I ${genome_path}/Picard_index/dedupped.bam -o ${out_path}/GATK_out/split.bam -rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 -U ALLOW_N_CIGAR_READS

