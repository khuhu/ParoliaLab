process MACS2_CALLPEAK {
    tag "${id}:${peak_type}"
    label 'process_low'
    container 'chipimage:latest'

    storeDir "${params.outdir}/${id}/macs2"

    input:
    tuple val(id), val(peak_type), path(bam), path(bai)
    path igg_bam

    output:
    tuple val(id), val(peak_type), path("${id}_peaks.${peak_type == 'broad' ? 'broadPeak' : 'narrowPeak'}"), emit: peaks
    tuple val(id), path("${id}_treat_pileup.bdg"),                                                            emit: bdg

    script:
    def broad_flag = peak_type == 'broad' ? '--broad' : ''
    """
    macs2 callpeak \\
        -t ${bam} \\
        -c ${igg_bam} \\
        -f BAMPE \\
        -B \\
        ${broad_flag} \\
        -n ${id} \\
        --outdir .
    """
}
