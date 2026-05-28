/*
 * GATK_MARKDUPLICATES
 * Mark PCR duplicates in a coordinate-sorted BAM.
 * Uses GATK's MarkDuplicates (not Picard standalone) for DNA samples.
 * Creates index automatically (CREATE_INDEX=true).
 */

process GATK_MARKDUPLICATES {
    tag "${meta.id}"
    label 'process_high_memory'

    publishDir "${params.outdir}/dna_preprocessing/markdup/${meta.id}", mode: 'copy',
        saveAs: { filename ->
            filename.endsWith('.dedup.bam') ||
            filename.endsWith('.dedup.bai') ||
            filename.endsWith('.metrics.txt') ? filename : null
        }

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}.dedup.bam"), path("${meta.id}.dedup.bai"), emit: bam_bai
    path "${meta.id}.markdup.metrics.txt",                                         emit: metrics

    script:
    // 80% of allocated memory goes to the Java heap; remaining 20% covers JVM
    // overhead, off-heap buffers, and the OS. MaxDirectMemorySize hard-caps the
    // direct byte buffer allocation that -Xmx alone does not control.
    def xmx_gb = (task.memory.toGiga() * 0.80).intValue()
    def xms_gb = Math.max(4, (xmx_gb * 0.40).intValue())
    """
    gatk --java-options "-Xms${xms_gb}G -Xmx${xmx_gb}G \\
        -XX:+UseSerialGC \\
        -XX:MaxDirectMemorySize=2G" \\
        MarkDuplicates \\
        --TMP_DIR ${params.tmp_dir} \\
        -I ${bam} \\
        -O ${meta.id}.dedup.bam \\
        -M ${meta.id}.markdup.metrics.txt \\
        --ASSUME_SORT_ORDER coordinate \\
        --CREATE_INDEX true \\
        --VALIDATION_STRINGENCY SILENT

    if [ -f ${meta.id}.dedup.bai ]; then
        :
    elif [ -f ${meta.id}.dedup.bam.bai ]; then
        mv ${meta.id}.dedup.bam.bai ${meta.id}.dedup.bai
    fi
    """
}
