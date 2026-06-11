process SAMTOOLS_FLAGSTAT {
    tag "${id}"
    label 'process_low'
    container 'eleanoyo/chipimage:latest'

    publishDir "${params.outdir}/${id}/flagstat", mode: 'copy'

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path("${id}_flagstat.txt"), emit: flagstat

    script:
    """
    samtools flagstat -@ ${task.cpus} ${bam} > ${id}_flagstat.txt
    """
}
