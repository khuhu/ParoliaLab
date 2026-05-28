/*
 * PICARD_MARKDUPLICATES
 * Mark PCR duplicates via GATK4's bundled MarkDuplicates.
 * Input:  coordinate-sorted BAM (no index required).
 * Output: deduplicated BAM + .bai index + metrics file.
 */

process PICARD_MARKDUPLICATES {
    tag "${meta.id}"
    label 'process_high_memory'

    publishDir "${params.outdir}/rna_processing/markdup/${meta.id}", mode: 'copy',
        saveAs: { filename ->
            filename.endsWith('.dedup.bam') ||
            filename.endsWith('.dedup.bai') ||
            filename.endsWith('.markdup.metrics.txt') ? filename : null
        }

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.dedup.bam"), path("${meta.id}.dedup.bai"), emit: bam_bai
    path "${meta.id}.markdup.metrics.txt",                                         emit: metrics

    script:
    def xmx_gb = (task.memory.toGiga() * 0.80).intValue()
    def xms_gb = Math.max(4, (xmx_gb * 0.40).intValue())
    """
    gatk --java-options "-Xms${xms_gb}g -Xmx${xmx_gb}g -XX:+UseSerialGC -XX:MaxDirectMemorySize=2g" \\
        MarkDuplicates \\
        --TMP_DIR ${params.tmp_dir} \\
        -I ${bam} \\
        -O ${meta.id}.dedup.bam \\
        -M ${meta.id}.markdup.metrics.txt \\
        --ASSUME_SORT_ORDER coordinate \\
        --CREATE_INDEX true \\
        --VALIDATION_STRINGENCY SILENT

    if [ -f ${meta.id}.dedup.bam.bai ]; then
        mv ${meta.id}.dedup.bam.bai ${meta.id}.dedup.bai
    fi
    """
}
