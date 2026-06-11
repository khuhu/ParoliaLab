#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { CHIPSEQ_PROCESSING } from './workflows/chipseq_processing.nf'

workflow {
    Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row ->
            def id = row.sample_id
            def fastq_dir = file(params.fastq_dir)
            def r1_files = fastq_dir.listFiles().findAll {
                it.name =~ /.*${id}.*_1\.fq\.gz$/
            }.sort()
            def r2_files = fastq_dir.listFiles().findAll {
                it.name =~ /.*${id}.*_2\.fq\.gz$/
            }.sort()
            if (!r1_files) error "No R1 FASTQ files found for sample ${id} in ${params.fastq_dir}"
            if (!r2_files) error "No R2 FASTQ files found for sample ${id} in ${params.fastq_dir}"
            tuple(id, r1_files, r2_files)
        }
        .set { raw_fastq_ch }

    CHIPSEQ_PROCESSING(raw_fastq_ch)
}
