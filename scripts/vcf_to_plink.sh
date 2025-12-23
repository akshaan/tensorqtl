#!/bin/bash
# Convert VCF to PLINK2 pgen/psam/pvar format
# Usage: vcf_to_plink.sh input.vcf.gz output_prefix
#
# --output-chr chrM: Standardizes chromosome names to 'chr' prefix (e.g., chr1, chr2, chrX)
#                    This ensures consistent chromosome naming with phenotype BED files

plink2 --vcf $1 \
       --make-pgen \
       --out $2 \
       --double-id \
       --set-missing-var-ids @:# \
       --vcf-half-call m \
       --allow-extra-chr \
       --output-chr chrM

