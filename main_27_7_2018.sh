## Define the path of your raw data and your scripts
mkdir -p rna_var && cd rna_var
work_dir=$(pwd)
mkdir -p $work_dir/{data,scripts,output,genomeDir,ref_vcf,annotation}
data=$work_dir/data
scripts=$work_dir/scripts
outDir=$work_dir/output
genomeDir=$work_dir/genomeDir
ref_vcf=$work_dir/ref_vcf
anno_dir=$work_dir/annotation
############################################################################################
## Data Download
################
## for each expermint you have to define the download links of the RNAseq sample, VCF file of the sample genome  and the matching reference genome 
## NA19240 (1000 genome sampel) illumina hiseq 2500, 51PE, ~59 million
sample="NA19240"
sample_R1_url="ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR105/005/ERR1050075/ERR1050075_1.fastq.gz"
sample_R2_url="ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR105/005/ERR1050075/ERR1050075_2.fastq.gz"
ref_vcf_url="ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA19240/cg_data/NA19240_lcl_SRR832874.wgs.COMPLETE_GENOMICS.20130401.snps_indels_svs_meis.high_coverage.genotypes.vcf.gz"
ref_genome="completegen_37"
ref_genome_url="ftp://ftp.completegenomics.com/ReferenceFiles/build37.fa.bz2"

## download
wget $sample_R1_url -P $work_dir/data ## gunzip
gunzip $sample_R1_url.fastq.gz
wget $sample_R2_url -P $work_dir/data ## gunzip
gunzip $sample_R2_url.fastq.gz
wget $ref_vcf_url -O $work_dir/ref_vcf/$sample.vcf.gz
wget $ref_vcf_url.tbi -O $work_dir/ref_vcf/$sample.vcf.gz.tbi
wget $ref_genome_url -O $work_dir/genomeDir/$ref_genome.fa.bz2 ## decompress
bzip2 -d $genomeDir/$ref_genome.fa.bz2
 
## GIAB NA12878: Multiple datasets 
## SRR1258218: illumina hiseq 2000, 75PE, ~26 million
## SRR1153470: illumina hiseq 2000, 101PE, ~115 million
sample="NA12878"
sample_accessions=("SRR1258218" "SRR1153470")
ref_vcf_url="ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/NA12878_HG001/latest/GRCh38/HG001_GRCh38_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_PGandRTGphasetransfer.vcf.gz"
ref_genome="ens_build38_release92"
ref_genome_url='ftp://ftp.ensembl.org/pub/release-92/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.chromosome.*.fa.gz' ## primaly assembly has unplaced contigs while the vcf has only chromosomes
ref_annot='ftp://ftp.ensembl.org/pub/release-92/gtf/homo_sapiens/Homo_sapiens.GRCh38.92.gtf.gz'

## download GIAB data using fastq-dump
cd $work_dir/data
module load GNU/4.4.5
module load SRAToolkit/2.8.2
wget ftp://ftp-trace.ncbi.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR115/SRR1153470/SRR1153470.sra
wget ftp://ftp-trace.ncbi.nih.gov/sra/sra-instant/reads/ByRun/sra/SRR/SRR125/SRR1258218/SRR1258218.sra
wget $ref_vcf_url -O $work_dir/ref_vcf/$sample.vcf.gz
gunzip $ref_vcf/$sample.vcf.gz#gunzip
wget $ref_vcf_url.tbi -O $work_dir/ref_vcf/$sample.vcf.gz.tbi
wget $ref_genome_url -P $work_dir/genomeDir
gunzip -c $work_dir/genomeDir/Homo_sapiens.GRCh38.dna.chromosome.*.fa.gz > $work_dir/genomeDir/$ref_genome.fa
rm $work_dir/genomeDir/Homo_sapiens.GRCh38.dna.chromosome.*.fa.gz 
sed -i 's/^>\(.*\) dna.*/>chr\1/' $work_dir/genomeDir/$ref_genome.fa
wget $ref_annot -O $anno_dir
mv work_dir/annotation/pub/release-92/gtf/homo_sapiens/*.gtf.gz $work_dir/annotation #the annotation file downloaded in this sequence of folders
gunzip $work_dir/annotation/*.gtf.gz

#fastq-dump for SRR1153470 and SRR1258218
fastq-dump --defline-seq '@$sn[_$rn]/$ri' --split-files $work_dir/data/SRR1153470.sra
fastq-dump --defline-seq '@$sn[_$rn]/$ri' --split-files $work_dir/data/SRR1258218.sra
rm $work_dir/data/SRR1153470.sra
rm $work_dir/data/SRR1258218.sra

## create a subset sample for testing
sample_accession="SRR1258218"
head -n4000000 $work_dir/data/${sample_accession}_1.fastq > $work_dir/data/${sample_accession}_subset_1.fastq
head -n4000000 $work_dir/data/${sample_accession}_2.fastq > $work_dir/data/${sample_accession}_subset_2.fastq
########################################################################################################

#genome indexing
STAR --runMode genomeGenerate --genomeDir $outDir --genomeFastaFiles $genomeDir/$ref_genome.fa --runThreadN 7
#sample mapping
cd $work_dir
mkdir -p STAR
STAR --genomeDir $outDir/ --readFilesIn $data/${sample_accession}_subset_1.fastq,$data/${sample_accession}_subset_2.fastq --outFileNamePrefix STAR/${sample_accession}_supset --sjdbGTFfile $anno_dir/* --runThreadN 7

#MarkDuplicates (Picard)
cd $work_dir
mkdir -p picard
#there is no output from this file
java -jar $picard MarkDuplicates I=STAR/${sample_accession}_supsetAligned.out.bam O=picard/marked_duplicates_${sample_accession}_subset.bam M=picard/marked_dup_metrics_${sample_accession}_subset.txt

## Varinat Calling 
## Change these variable to define the input files
sample="NA12878"                     # the reference VCF will be  $ref_vcf/$sample.vcf.gz                
read="SRR1258218_subset"             # the reads will be R1=$data/${read}_1.fastq   R2=$data/${read}_2.fastq
ref_genome="ens_build38_release92"   # the reference will be $genomeDir/$ref_genome.fa

## version 1







#######################################################################################################
## Calculation of senstivity and Scpecificty 

