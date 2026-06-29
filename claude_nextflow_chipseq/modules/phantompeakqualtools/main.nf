process PHANTOMPEAKQUALTOOLS {
    tag "${id}"
    label 'process_medium'
    container 'quay.io/biocontainers/phantompeakqualtools:1.2.2--0'

    publishDir { "${params.outdir}/${id}/phantompeakqualtools" }, mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)

    output:
    tuple val(id), path("${id}_spp.out"),  emit: spp
    tuple val(id), path("${id}_spp.pdf"),  emit: plot

    script:
    """
    run_spp.R \\
        -c=${bam} \\
        -p=${task.cpus} \\
        -savp=${id}_spp.pdf \\
        -out=${id}_spp.out \\
        -rf
    """
}
