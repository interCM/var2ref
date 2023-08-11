#!/bin/bash

source ${HOME}/py_envs/bio/bin/activate
which bcftools

# Input arguments:
VCF="../data/GCF_000001405.25.gz"
CHROM_RENAME_FNAME="../data/RefSeqChrMap.GRCh37.p13.txt" # A file with two columns: (1) RefSeq chromosome name (2) new chromosome name (e.g. 1..22, X, Y, MT) 

# Creates "${VCF}.chr{1..22,X,Y,MT}.txt" files with 5 columns: RSID (only integer, no "rs" prefix), CHROM, POS, REF, ALT (single alt allele, multiallelic variants are split).

CHROM=$(cut -f2 ${CHROM_RENAME_FNAME} | paste -d, -s) # Use only chromosomes listed in the CHROM_RENAME_FNAME
echo "New chromosome names: ${CHROM}"

# The type of the RS field from the INFO column should be changed to string. See why this is needed: https://github.com/samtools/bcftools/issues/1961
# Otherwise bcftools fails to process it correctly.
bcftools view -h ${VCF} > ${VCF}.header.txt
sed -i "s/ID=RS,Number=1,Type=Integer/ID=RS,Number=1,Type=String/" ${VCF}.header.txt
bcftools reheader -h ${VCF}.header.txt -o ${VCF}.bcf ${VCF}
# bcftools index ${VCF}.bcf

bcftools annotate --rename-chrs ${CHROM_RENAME_FNAME} -x "INFO" -Ou ${VCF}.bcf | \
	bcftools norm -m - -t ${CHROM} -Ou | bcftools query -f '%ID\t%CHROM\t%POS\t%REF\t%ALT\n' | \
	sed 's/^rs//' | awk -v FS='\t' -v OUT="${VCF}" 'BEGIN{OFS="\t"} {print($1,$2,$3,$4,$5) >> OUT".chr"$2".txt"}'
