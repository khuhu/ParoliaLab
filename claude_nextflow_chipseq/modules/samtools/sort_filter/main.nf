process SAMTOOLS_SORT_FILTER {
    tag "${id}"
    label 'process_medium'
    container 'eleanoyo/chipimage:latest'

    input:
    tuple val(id), path(sam)

    output:
    tuple val(id), path("${id}_filtered_sorted_aligned.sam"), emit: filtered_sam

    script:
    """
    samtools sort ${sam} -o ${id}_sorted_aligned.sam
    samtools view -hq 20 ${id}_sorted_aligned.sam -o ${id}_filtered_sorted_aligned.sam
    """
}
