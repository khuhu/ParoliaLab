process SAMTOOLS_INDEX {
    tag "${id}"
    label 'process_low'
    container 'chipimage:latest'

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path(bam), path("${bam}.bai"), emit: indexed_bam

    script:
    """
    samtools index -@ ${task.cpus} ${bam}
    """
}
