# RNA Processing

## Overview

The RNA processing workflow aligns RNA-seq reads from xengsort-classified human (graft) FASTQs, marks duplicates, and computes quality metrics. The primary output is a gene-level expression GCT file from RNA-SeQC, plus quality metrics to assess library quality.

This arm uses parameters tuned for the GTEx pipeline, which has been widely validated for human transcriptomics and is appropriate for cancer RNA-seq.

## Steps

```
[graft R1, R2 .fq.gz FASTQs]
             |
         STAR_ALIGN
    (two-pass, chimeric reads)
             |
   [Aligned.out.bam (Unsorted)]
             |
       SAMTOOLS_SORT
    (coordinate sort, required
     by Picard and RNA-SeQC)
             |
   PICARD_MARKDUPLICATES
    (flag PCR duplicates)
             |
   [{sample}.dedup.bam + .bai]
             |
          RNASEQC
    (QC metrics + gene counts)
             |
  [{sample}.gene_reads.gct]
  [{sample}.metrics.tsv]
```

## Step Details

### 1. STAR_ALIGN — RNA Alignment

**Tool**: STAR (Spliced Transcripts Alignment to a Reference)

STAR is a splice-aware aligner that handles introns correctly for RNA-seq. Unlike BWA (which does not know about splice junctions), STAR can align reads that span exon-exon boundaries.

**Index**: Pre-built STAR genome index at `params.star_index`
(GRCh38, no ALT/HLA/Decoy contigs, ERCC spike-ins, overhang=100)

**Reference GTF**: `params.gtf` (Gencode v39 with ERCC, stranded)

**Mode**: `--twopassMode Basic` — STAR first discovers novel splice junctions in pass 1, then realigns all reads with those junctions in pass 2. This improves sensitivity for novel transcripts and fusion detection.

**Key GTEx-tuned parameters**:

| Parameter | Value | Meaning |
|---|---|---|
| `--outFilterMultimapNmax 20` | 20 | Allow reads mapping to up to 20 locations |
| `--alignSJoverhangMin 8` | 8 | Minimum overhang at unannotated junctions |
| `--alignSJDBoverhangMin 1` | 1 | Minimum overhang at annotated junctions |
| `--outFilterMismatchNmax 999` | 999 | No hard limit on mismatches (controlled by ratio below) |
| `--outFilterMismatchNoverLmax 0.1` | 0.1 | Max 10% mismatches per read |
| `--alignIntronMin 20` | 20 | Minimum intron size |
| `--alignIntronMax 1000000` | 1e6 | Maximum intron size |
| `--alignMatesGapMax 1000000` | 1e6 | Maximum gap between mates |
| `--outFilterType BySJout` | — | Filter reads by junction annotation after pass 2 |
| `--limitSjdbInsertNsj 1200000` | 1.2e6 | Allow many novel junctions |

**Chimeric read detection** (fusion detection):
| Parameter | Value |
|---|---|
| `--chimSegmentMin 15` | Minimum chimeric segment length |
| `--chimJunctionOverhangMin 15` | Minimum junction overhang |
| `--chimOutType Junctions WithinBAM SoftClip` | Write junctions + chimeric alignments in BAM |
| `--chimMainSegmentMultNmax 1` | Require chimeric main segment to be unique |

**Quantification**:
- `--quantMode TranscriptomeSAM GeneCounts`: produces both a transcriptome-aligned BAM (for tools like RSEM) and a read-count table per gene

**Output format**: `--outSAMtype BAM Unsorted` — STAR outputs unsorted BAM; we sort in the next step.

**Output files**:
| File | Description |
|---|---|
| `{sample}Aligned.out.bam` | Genomic alignments (input to downstream) |
| `{sample}Aligned.toTranscriptome.out.bam` | Transcriptome alignments (for RSEM etc.) |
| `{sample}ReadsPerGene.out.tab` | Raw gene counts (4 columns: gene, unstranded, fwd, rev) |
| `{sample}Chimeric.out.junction` | Chimeric/fusion junction calls |
| `{sample}Log.final.out` | STAR alignment summary statistics |
| `{sample}SJ.out.tab` | Splice junction table |

### 2. SAMTOOLS_SORT

Coordinate-sorts the STAR-output BAM. Required by Picard and RNA-SeQC (both expect coordinate-sorted input).

Same process module as in the DNA arm (`modules/samtools/sort/main.nf`), demonstrating DSL2 module reuse.

### 3. PICARD_MARKDUPLICATES

**Tool**: Picard MarkDuplicates (JAR-based, not GATK wrapper)

Marks PCR duplicate read pairs based on identical mapping positions. RNA-seq duplicate rates are typically higher than WES because:
- Highly expressed genes have many reads starting at the same position
- Short transcripts concentrate reads in limited positions

Duplicates are marked (flagged) but not removed. RNA-SeQC and most count-based tools ignore flagged duplicates.

**Key settings**:
- `-XX:ParallelGCThreads=8`: 8 GC threads for JVM garbage collection
- `ASSUME_SORT_ORDER=coordinate`: skips re-sorting (already sorted)
- `CREATE_INDEX=true`: outputs `.bai`
- `VALIDATION_STRINGENCY=SILENT`

**Output**:
- `{sample}.dedup.bam` + `{sample}.dedup.bai`
- `{sample}.markdup.metrics.txt`

### 4. RNASEQC — Quality Metrics and Gene Counts

**Tool**: RNA-SeQC v2 (`rnaseqc`)

RNA-SeQC computes a comprehensive set of RNA-seq quality metrics:
- rRNA rate
- Exonic rate / intronic rate / intergenic rate
- Read distribution across genomic features
- 5' to 3' coverage bias (important for degraded RNA)
- Mapping rate and quality
- Gene expression correlation

**Stranded mode**: `--stranded rf` — the library is reverse-stranded (reads are on the opposite strand from the gene). This is the standard for Illumina TruSeq RNA kits. If using unstranded or forward-stranded libraries, change this parameter.

**Output files**:
| File | Description |
|---|---|
| `{sample}.gene_reads.gct` | Gene-level read counts (GCT format) |
| `{sample}.metrics.tsv` | Per-sample QC metrics table |
| `{sample}.exon_reads.gct` | Exon-level read counts |

## Output Directory Structure

```
{outdir}/rna_processing/
├── star/{sample}/
│   ├── {sample}Aligned.out.bam
│   ├── {sample}Aligned.toTranscriptome.out.bam
│   ├── {sample}ReadsPerGene.out.tab
│   ├── {sample}Chimeric.out.junction
│   ├── {sample}Log.final.out
│   └── {sample}SJ.out.tab
├── markdup/{sample}/
│   ├── {sample}.dedup.bam
│   ├── {sample}.dedup.bai
│   └── {sample}.markdup.metrics.txt
└── rnaseqc/{sample}/
    ├── {sample}.gene_reads.gct
    ├── {sample}.metrics.tsv
    └── {sample}.exon_reads.gct
```

## Quality Thresholds

| Metric | Acceptable Range | Notes |
|---|---|---|
| Mapping rate | >85% | Low rate suggests contamination or wrong reference |
| rRNA rate | <20% | High rate suggests rRNA depletion failed |
| Exonic rate | >50% | RNA-seq should be mostly exonic |
| Duplicate rate | 20-70% | RNA-seq can have high duplicates; very high (>80%) suggests low library complexity |
| 5'/3' bias | 0.8-1.2 | Bias >1.5 suggests RNA degradation |
| Unique mapping rate | >70% | Low unique rate suggests repetitive element contamination |

## Using Gene Counts Downstream

The `{sample}.gene_reads.gct` files from RNA-SeQC can be used directly with:
- **DESeq2** for differential expression (after extracting the count matrix)
- **TPMCalculator** for TPM normalization
- **GTEx analysis pipeline** (these parameters were tuned for GTEx compatibility)
- **RSEM** with the `Aligned.toTranscriptome.out.bam` for isoform-level quantification

## Adjusting for Library Type

If your libraries are **unstranded** (e.g., older protocols):
```yaml
# Not currently a parameter — edit modules/rnaseqc/main.nf
# Change --stranded rf to --stranded no (or remove the flag)
```

If your libraries are **forward-stranded**:
```yaml
# Change --stranded rf to --stranded fr
```
