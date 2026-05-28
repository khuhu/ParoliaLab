/*
 * GATK_BASERECALIBRATOR
 * Compute per-base quality score recalibration (BQSR) table.
 * Uses dbSNP, known indels (1000G), and Mills indels as known sites.
 */

nextflow.enable.dsl = 2

process GATK_BASERECALIBRATOR {
    tag "${meta.id}"
    label 'process_medium'

    publishDir "${params.outdir}/dna_preprocessing/bqsr/${meta.id}", mode: 'copy',
        saveAs: { filename -> filename.endsWith('.recal.table') ? filename : null }

    input:
    tuple val(meta),
          path(bam),
          path(bai),
          path(ref),
          path(ref_fai),
          path(dbsnp),
          path(indels),
          path(indels_tbi),
          path(mills),
          path(mills_tbi)

    output:
    tuple val(meta), path("${meta.id}.recal.table"), emit: recal_table

    script:
    def xmx_gb = (task.memory.toGiga() * 0.80).intValue()
    def xms_gb = Math.max(4, (xmx_gb * 0.40).intValue())
    """
    gatk --java-options "-Xms${xms_gb}G -Xmx${xmx_gb}G \\
        -XX:+UseSerialGC \\
        -XX:ParallelGCThreads=2 \\
        -XX:MaxDirectMemorySize=2G" \\
        BaseRecalibrator \\
        -I ${bam} \\
        -R ${ref} \\
        --known-sites ${dbsnp} \\
        --known-sites ${indels} \\
        --known-sites ${mills} \\
        -O ${meta.id}.recal.table \\
        --tmp-dir ${params.tmp_dir}
    """
}
