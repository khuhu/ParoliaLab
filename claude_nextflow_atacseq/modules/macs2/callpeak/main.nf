process MACS2_CALLPEAK {
    tag "${id}"
    label 'process_low'
    container 'chipimage:latest'

    storeDir "${params.outdir}/${id}/macs2"

    input:
    tuple val(id), path(bam)

    output:
    tuple val(id), path("${id}_peaks.narrowPeak"),   emit: peaks
    tuple val(id), path("${id}_treat_pileup.bdg"),   emit: bdg

    script:
    """
    macs2 callpeak \\
        -t ${bam} \\
        -n ${id} \\
        -g hs \\
        -f BAMPE \\
        -B \\
        -q 0.001 \\
        --nolambda \\
        --SPMR \\
        --outdir .
    """
}
