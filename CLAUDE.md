# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nextflow (DSL2) bioinformatics pipeline for Ewing's Sarcoma RNA-seq data analysis, developed in the Parolia Lab at MCTP. The pipeline processes paired-end FASTQ files through alignment, deduplication, and quality control, targeting GTEx-compatible RNA-seq standards.

## Running the Pipeline

```bash
# Local execution (uses standard profile: 33 CPUs, 8 concurrent processes)
nextflow run claude_nextflow/main.nf -params-file claude_nextflow/params.yaml

# HPC cluster execution (SLURM, Parolia account)
nextflow run claude_nextflow/main.nf -params-file claude_nextflow/params.yaml -profile slurm

# Resume a failed run (Nextflow caching)
nextflow run claude_nextflow/main.nf -params-file claude_nextflow/params.yaml -resume
```

## Architecture

```
main.nf  →  RNA_PROCESSING workflow  →  STAR_ALIGN → SAMTOOLS_SORT → PICARD_MARKDUPLICATES → RNASEQC
```

All paths are under `claude_nextflow/`:
- `main.nf` — Entry point; reads samplesheet, builds FASTQ input channels, calls `RNA_PROCESSING`
- `nextflow.config` — Executor profiles (`standard`, `slurm`), resource labels, reference file paths
- `params.yaml` — Run-specific inputs: FASTQ directory, STAR index, GTF, output directory
- `workflows/rna_processing.nf` — Top-level RNA workflow definition
- `modules/` — DSL2 process modules (samtools, gatk, rnaseqc, star)

## Workflow Steps

1. **STAR_ALIGN** — Two-pass splice-aware alignment with GTEx-tuned parameters; outputs genomic BAM, transcriptome BAM, gene counts (ReadsPerGene.out.tab), and chimeric junction file for fusion detection
2. **SAMTOOLS_SORT** — Coordinate-sorts the genomic BAM (required by downstream tools)
3. **PICARD_MARKDUPLICATES** — Marks PCR duplicates; **this module is currently missing** (`modules/picard/markduplicates/main.nf` does not exist); pipeline will fail until created or replaced with `GATK_MARKDUPLICATES`
4. **RNASEQC** — Produces GCT gene counts and QC metrics TSV (exonic/intronic/rRNA rates, 5'/3' bias)

## Conda Environment

Only `nextflow` and `STAR` are installed by default. Additional packages required:

```bash
conda install -c bioconda samtools rnaseqc
conda install -c conda-forge openjdk openpyxl
```

- `samtools` — coordinate-sort BAM after STAR alignment
- `rnaseqc` — RNA quality metrics
- `openjdk` — Java runtime for the Picard JAR (`params.picard_jar`)
- `openpyxl` — Python library used by the `XLSX_TO_TSV` process to parse the XLSX samplesheet

## Resource Labels (nextflow.config)

| Label | CPUs | Memory | Time |
|-------|------|--------|------|
| process_low | 2 | 8 GB | 4h |
| process_medium | 8 | 32 GB | 12h |
| process_high | 12 | 48 GB | 24h |
| process_high_memory | 4 | 64 GB | 24h |

GATK processes use Java heap set to 80% of allocated memory (`-Xmx${(task.memory.mega * 0.8).intValue()}m`).

## Reference File Paths

All reference data lives on the MCTP cluster under `/mctp/paroliaAnalysis/kevhu/`. Key references used in `params.yaml`:
- STAR index: GRCh38 + ERCC spike-ins, overhang=100
- GTF: Gencode v39 (stranded, includes ERCC)
- Known sites for BQSR: dbSNP, Mills, 1000G indels

## Input Format

The samplesheet CSV must include a column named `libraries_library_id`. FASTQ paths are constructed from `params.rna_fastq_dir` using the pattern `{id}_R1*.fastq.gz` / `{id}_R2*.fastq.gz`.

## Quality Thresholds (from docs/README_rna_processing.md)

- Mapping rate: >85%
- rRNA rate: <20%
- Exonic rate: >50%
- Duplicate rate: 20–70%
- 5'/3' bias: 0.8–1.2

## GATK Somatic Variant Modules

The `modules/gatk/` directory also contains infrastructure for somatic variant calling (Mutect2 → FilterMutectCalls → Funcotator → MAF). These are not currently wired into the RNA workflow but are available for future DNA/WGS analysis use.
