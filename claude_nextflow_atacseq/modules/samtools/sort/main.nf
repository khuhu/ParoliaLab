process SAMTOOLS_SORT {
    tag "${id}"
    label 'process_medium'
    container 'atacimage:latest'

    storeDir "${params.outdir}/${id}/samtools"

    input:
    tuple val(id), path(sam)

    output:
    tuple val(id), path("${id}_sort.bam"), emit: bam

    script:
    def mem_per_thread = (task.memory.mega / task.cpus).intValue()
    """
    samtools sort -@ ${task.cpus} -m ${mem_per_thread}M ${sam} -o ${id}_sort.bam
    """
}
