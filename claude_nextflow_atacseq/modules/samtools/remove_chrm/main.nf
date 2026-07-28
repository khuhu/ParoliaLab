process REMOVE_CHRM {
    tag "${id}"
    label 'process_medium'
    container 'atacimage:latest'

    storeDir "${params.outdir}/${id}/samtools"

    input:
    tuple val(id), path(sam)

    output:
    tuple val(id), path("${id}_nochrM_sort.bam"), emit: bam
    path("${id}.sam.gz"),                         emit: archived_sam

    script:
    """
    gzip -c ${sam} > ${id}.sam.gz
    zcat ${id}.sam.gz \\
        | sed '/chrM/d' \\
        | samtools view -bS -@ ${task.cpus} - \\
        | samtools sort -@ ${task.cpus} - -o ${id}_nochrM_sort.bam
    """
}
