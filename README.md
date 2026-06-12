# Parolia Lab — Ewing's Sarcoma Nextflow Pipelines

Claude-assisted conversion of lab shell scripts into Nextflow DSL2 pipelines. Built as a learning opportunity to move from ad-hoc bash/Docker scripts toward reproducible, resumable, parallelized pipeline management with Nextflow.

---

## Pipelines

### 1. RNA-seq (`claude_nextflow/`)

Based on the Broad Institute pipeline, aligned with CCLE processing standards.

**Steps:** STAR (two-pass) → Samtools sort → Picard MarkDuplicates → RNA-SeQC → STAR-Fusion → Arriba

**Run:**
```bash
nextflow run claude_nextflow/main.nf -params-file claude_nextflow/params.yaml
```

---

### 2. ChIP-seq (`claude_nextflow_chipseq/`)

Converted from Eleanor's shell scripts (`RunChip.sh` / `ChipPipe_v3_PE.sh`) into Nextflow.

**Steps:** Merge lanes → Trimmomatic → BWA → Samtools sort/filter → Picard MarkDuplicates → MACS2 (with IgG control) → Bedtools blacklist filter → wigToBigWig → Samtools flagstat

**Run:**
```bash
nextflow run claude_nextflow_chipseq/main.nf -params-file claude_nextflow_chipseq/params.yaml -profile standard
```

**Resume a failed run:**
```bash
nextflow run claude_nextflow_chipseq/main.nf -params-file claude_nextflow_chipseq/params.yaml -profile standard -resume
```

---

## Lab-Specific Notes

**Lane merging** — MCTP/Parolia lab FASTQ files are named with a `SI_XXXXX` sample ID pattern (e.g. `mctp_SI_38051_H2HT5DSXC_3_1.fq.gz`). The pipeline automatically finds and merges all per-lane files for each sample ID.

**Samplesheet** — A simple CSV with a `library_id` column listing SI IDs. Generate from a FASTQ directory:
```bash
echo "library_id" > ChipSeqLibraries_EwingSarcoma.csv
ls *.fq.gz | grep -oP 'SI_\d+' | sort -u >> ChipSeqLibraries_EwingSarcoma.csv
```

**Reference files** — Sourced from Eleanor's REF directory and copied into `pipelineFiles/` (gitignored — lives on the server only). Files needed:
- `genome.fa` + BWA index files (`.amb .ann .bwt .pac .sa`)
- `hg38.genome` (chromosome sizes)
- `FixBlacklist_ENCFF356LFX.bed`
- `SI_40572_VCaP_DMSO_IgG_aligned_PCRDupes.bam` + `.bai` (IgG control for MACS2)
- `TruSeq3-PE-2.fa` (Trimmomatic adapters)

**Docker** — ChIP-seq uses `chipimage:latest` (loaded from tar). Trimmomatic uses a local conda environment (`trimmomatic_env`).

---

## Requirements

- Nextflow >= 23.04
- Java 17+
- Docker
- Conda (for Trimmomatic)

---

## Repository Structure

```
claude_nextflow/              # RNA-seq pipeline
claude_nextflow_chipseq/      # ChIP-seq pipeline
  modules/                    # Individual DSL2 process modules
  workflows/                  # Top-level workflow definitions
  main.nf                     # Entry point
  nextflow.config             # Executor, resource labels, profiles
  params.yaml                 # All file paths and parameters
pipelineFiles/                # Reference files (gitignored, server only)
RunChip.sh                    # Original shell script (reference)
ChipPipe_v3_PE.sh             # Original Docker script (reference)
```
