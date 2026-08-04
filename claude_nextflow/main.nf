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

// ─────────────────────────────────────────────
// MAIN WORKFLOW
// ─────────────────────────────────────────────
workflow {

    // Build [meta, r1, r2] channel from TSV samplesheet
    // Column name: 'Library ID'
    // FASTQ naming: mctp_<sample_id>_R1.fq.gz / mctp_<sample_id>_R2.fq.gz
    ch_rna_reads = Channel
        .fromPath(params.rna_samplesheet, checkIfExists: true)
        .splitCsv(header: true, sep: '\t', strip: true, charset: 'ISO-8859-1')
        .map { row ->
            def sample_id = row['Library ID'].trim()
            def r1 = file("${params.rna_fastq_dir}/mctp_${sample_id}_R1.fq.gz")
            def r2 = file("${params.rna_fastq_dir}/mctp_${sample_id}_R2.fq.gz")
            [[id: sample_id], r1, r2]
        }

    RNA_PROCESSING(ch_rna_reads)
}
