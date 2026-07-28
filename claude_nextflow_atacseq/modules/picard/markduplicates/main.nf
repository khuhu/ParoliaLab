process PICARD_MARKDUPLICATES {
    tag "${id}"
    label 'process_high_memory'
    container 'atacimage:latest'

    storeDir "${params.outdir}/${id}/picard"

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path("${id}_nochrM_sort_rmd.bam"), path("${id}_nochrM_sort_rmd.bai"), emit: bam_bai
    path("${id}_nochrM_sort_rmd_metrics.txt"),                                           emit: metrics

    script:
    def jvm_mem = (task.memory.mega * 0.8).intValue()
    """
    java -Xmx${jvm_mem}m -jar /picard/build/libs/picard.jar MarkDuplicates \\
        -INPUT ${bam} \\
        -OUTPUT ${id}_nochrM_sort_rmd.bam \\
        -REMOVE_DUPLICATES true \\
        -ASSUME_SORTED true \\
        -METRICS_FILE ${id}_nochrM_sort_rmd_metrics.txt \\
        -CREATE_INDEX true \\
        -VALIDATION_STRINGENCY SILENT
    """
}
