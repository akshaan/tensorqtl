plink2 --vcf $1 \
       --make-pgen \
       --out $2 \
       --double-id \
       --set-missing-var-ids @:# \
       --vcf-half-call m \
       --allow-extra-chr

