process MERGE_LANES {
    tag "${id}"
    label 'process_low'

    publishDir "${params.outdir}/${id}/fastq_merged", mode: 'copy', enabled: false

    input:
    tuple val(id), path(r1_files), path(r2_files)

    output:
    tuple val(id), path("${id}_R1.fq.gz"), path("${id}_R2.fq.gz"), emit: merged_fastq

    script:
    """
    cat ${r1_files} > ${id}_R1.fq.gz
    cat ${r2_files} > ${id}_R2.fq.gz
    """
}
