process PICARD_COLLECTINSERTSIZEMETRICS {
    tag "${id}"
    label 'process_medium'
    container 'atacimage:latest'

    storeDir "${params.outdir}/${id}/reports"

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path("${id}_size.txt"), path("${id}_size.pdf"), emit: metrics

    script:
    def jvm_mem = (task.memory.mega * 0.8).intValue()
    """
    java -Xmx${jvm_mem}m -jar /picard/build/libs/picard.jar CollectInsertSizeMetrics \\
        -INPUT ${bam} \\
        -OUTPUT ${id}_size.txt \\
        -HISTOGRAM_FILE ${id}_size.pdf
    """
}
