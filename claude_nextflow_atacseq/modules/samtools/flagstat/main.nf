process SAMTOOLS_FLAGSTAT {
    tag "${id}"
    label 'process_low'
    container 'atacimage:latest'

    storeDir "${params.outdir}/${id}/reports"

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path("${bam.baseName}_flagstat.txt"), emit: flagstat

    script:
    """
    samtools flagstat -@ ${task.cpus} ${bam} > ${bam.baseName}_flagstat.txt
    """
}
