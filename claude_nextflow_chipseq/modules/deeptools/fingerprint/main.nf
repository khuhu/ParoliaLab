process DEEPTOOLS_FINGERPRINT {
    tag "${id}"
    label 'process_medium'
    container 'chipimage:latest'

    publishDir { "${params.outdir}/${id}/deeptools" }, mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)
    path igg_bam

    output:
    tuple val(id), path("${id}_fingerprint.png"),    emit: plot
    tuple val(id), path("${id}_fingerprint.tab"),    emit: counts

    script:
    """
    plotFingerprint \\
        -b ${bam} ${igg_bam} \\
        --labels ${id} IgG \\
        --numberOfSamples 500000 \\
        -p ${task.cpus} \\
        --plotFile ${id}_fingerprint.png \\
        --outRawCounts ${id}_fingerprint.tab
    """
}
