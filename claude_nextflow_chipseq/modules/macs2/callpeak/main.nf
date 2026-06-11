process MACS2_CALLPEAK {
    tag "${id}"
    label 'process_low'
    container 'chipimage:latest'

    publishDir { "${params.outdir}/${id}/macs2" }, mode: 'copy'

    input:
    tuple val(id), path(bam), path(bai)
    path igg_bam

    output:
    tuple val(id), path("${id}_peaks.narrowPeak"),       emit: narrowpeak
    tuple val(id), path("${id}_treat_pileup.bdg"),        emit: bdg

    script:
    """
    macs2 callpeak \\
        -t ${bam} \\
        -c ${igg_bam} \\
        -f BAMPE \\
        -B \\
        -n ${id} \\
        --outdir .
    echo "${id} macs2 finished \$(date)" >> Log.log
    """
}
