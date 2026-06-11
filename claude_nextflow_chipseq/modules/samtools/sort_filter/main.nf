process SAMTOOLS_SORT_FILTER {
    tag "${id}"
    label 'process_medium'
    container 'chipimage:latest'

    input:
    tuple val(id), path(sam)

    output:
    tuple val(id), path("${id}_filtered_sorted_aligned.sam"), emit: filtered_sam

    script:
    def mem_per_thread = (task.memory.mega / task.cpus).intValue()
    """
    samtools sort -@ ${task.cpus} -m ${mem_per_thread}M ${sam} -o ${id}_sorted_aligned.sam
    samtools view -@ ${task.cpus} -hq 20 ${id}_sorted_aligned.sam -o ${id}_filtered_sorted_aligned.sam
    """
}
