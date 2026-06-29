process SAMTOOLS_FLAGSTAT {
    tag "${id}"
    label 'process_low'
    container 'chipimage:latest'

    storeDir "${params.outdir}/${id}/flagstat"

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path("${id}_flagstat.txt"), emit: flagstat

    script:
    """
    samtools flagstat -@ ${task.cpus} ${bam} > ${id}_flagstat.txt
    """
}
