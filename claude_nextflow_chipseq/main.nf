#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { CHIPSEQ_PROCESSING } from './workflows/chipseq_processing.nf'

workflow {
    Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row ->
            def id = row.library_id
            def peak_type = row.containsKey('peak_type') ? row.peak_type : 'narrow'
            def fastq_dir = file(params.fastq_dir)
            def r1_files = fastq_dir.listFiles().findAll {
                it.name.contains(id) && it.name.endsWith('_1.fq.gz')
            }.sort()
            def r2_files = fastq_dir.listFiles().findAll {
                it.name.contains(id) && it.name.endsWith('_2.fq.gz')
            }.sort()
            if (!r1_files) error "No R1 FASTQ files found for sample ${id} in ${params.fastq_dir}"
            if (!r2_files) error "No R2 FASTQ files found for sample ${id} in ${params.fastq_dir}"
            tuple(id, peak_type, r1_files, r2_files)
        }
        .set { raw_fastq_ch }

    CHIPSEQ_PROCESSING(raw_fastq_ch)
}
