#!/usr/bin/env nextflow
/*
 * Parolia Lab Ewings Sarcoma Pipeline — Main Entry Point
 *
 * Runs:
 *   1. RNA processing (STAR → Picard dedup → RNA-SeQC)
 *
 * To run:
 *   nextflow run main.nf -params-file params.yaml
 */

nextflow.enable.dsl = 2

// ─────────────────────────────────────────────
// WORKFLOW IMPORTS
// ─────────────────────────────────────────────
include { RNA_PROCESSING } from './workflows/rna_processing'
include { MERGE_LANES    } from './modules/merge_lanes/main'

// ─────────────────────────────────────────────
// MAIN WORKFLOW
// ─────────────────────────────────────────────
workflow {

    // Build [meta, r1_files, r2_files] channel from TSV samplesheet.
    // Column name: 'Library ID'
    // Matches every FASTQ in rna_fastq_dir containing the sample ID, whether
    // it's already a single merged file (mctp_<id>_R1.fq.gz, legacy layout)
    // or multiple per-lane files (mctp_<id>_L00X_1.fq.gz) — MERGE_LANES cats
    // whatever is found into one R1/R2 pair per sample.
    ch_raw_reads = Channel
        .fromPath(params.rna_samplesheet, checkIfExists: true)
        .splitCsv(header: true, sep: '\t', strip: true, charset: 'ISO-8859-1')
        .map { row ->
            def sample_id = row['Library ID'].trim()
            def fastq_dir = file(params.rna_fastq_dir)
            def r1_files = fastq_dir.listFiles().findAll {
                it.name.contains(sample_id) && (it.name.endsWith('_1.fq.gz') || it.name.endsWith('_R1.fq.gz'))
            }.sort()
            def r2_files = fastq_dir.listFiles().findAll {
                it.name.contains(sample_id) && (it.name.endsWith('_2.fq.gz') || it.name.endsWith('_R2.fq.gz'))
            }.sort()
            if (!r1_files) error "No R1 FASTQ files found for sample ${sample_id} in ${params.rna_fastq_dir}"
            if (!r2_files) error "No R2 FASTQ files found for sample ${sample_id} in ${params.rna_fastq_dir}"
            [[id: sample_id], r1_files, r2_files]
        }

    MERGE_LANES(ch_raw_reads)

    RNA_PROCESSING(MERGE_LANES.out.merged_fastq)
}
