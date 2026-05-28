/*
 * GATK_APPLYBQSR
 * Apply the BQSR recalibration table to produce the final analysis-ready BAM.
 * Output: coordinate-sorted, deduplicated, recalibrated BAM + index.
 */

nextflow.enable.dsl = 2

process GATK_APPLYBQSR {
    tag "${meta.id}"
    label 'process_medium'

    publishDir "${params.outdir}/dna_preprocessing/bqsr/${meta.id}", mode: 'copy',
        saveAs: { filename ->
            filename.endsWith('.dedup.bqsr.bam') ||
            filename.endsWith('.dedup.bqsr.bai') ? filename : null
        }

    input:
    tuple val(meta),
          path(bam),
          path(bai),
          path(recal_table),
          path(ref)

    output:
    tuple val(meta),
          path("${meta.id}.dedup.bqsr.bam"),
          path("${meta.id}.dedup.bqsr.bai"),
          emit: bam_bai

    script:
    def xmx_gb = (task.memory.toGiga() * 0.80).intValue()
    def xms_gb = Math.max(4, (xmx_gb * 0.40).intValue())
    """
    gatk --java-options "-Xms${xms_gb}G -Xmx${xmx_gb}G \\
        -XX:+UseSerialGC \\
        -XX:ParallelGCThreads=2 \\
        -XX:MaxDirectMemorySize=2G" \\
        ApplyBQSR \\
        -I ${bam} \\
        -R ${ref} \\
        --bqsr-recal-file ${recal_table} \\
        -O ${meta.id}.dedup.bqsr.bam \\
        --create-output-bam-index true \\
        --tmp-dir ${params.tmp_dir}

    if [ -f ${meta.id}.dedup.bqsr.bai ]; then
        :
    elif [ -f ${meta.id}.dedup.bqsr.bam.bai ]; then
        mv ${meta.id}.dedup.bqsr.bam.bai ${meta.id}.dedup.bqsr.bai
    fi
    """
}
