from typing import Literal
from pathlib import Path


class Dataset:
    name: str
    genotype_path: Path
    phenotype_path: Path
    covariates_path: Path
    output_prefix: str
    modes: list[Literal["cis", "trans"]]


GEUVADIS_DATASET = Dataset(
    name="geuvadis",
    genotype_path=Path("example/data/GEUVADIS.445_samples.GRCh38.20170504.maf01.filtered.nodup.chr18"),
    phenotype_path=Path("example/data/GEUVADIS.445_samples.expression.bed.gz"),
    covariates_path=Path("example/data/GEUVADIS.445_samples.covariates.txt"),
    output_prefix="GEUVADIS.445_samples",
    modes=["cis"]
)

RAT_GTEx_DATASET = Dataset(
    name="rat_gtex",
    genotype_path=Path("example/ratGTEx/rat_gtex/genotypes.bed.gz"),
    phenotype_path=Path("example/ratGTEx/rat_gtex/phenotypes.bed.gz"),
    covariates_path=Path("example/ratGTEx/rat_gtex/covariates.txt"),
    output_prefix="RatGTEx_v4",
    modes=["cis", "trans"]
)

DATASETS = [GEUVADIS_DATASET, RAT_GTEx_DATASET]