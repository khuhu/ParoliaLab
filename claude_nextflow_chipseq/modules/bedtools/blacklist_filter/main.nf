process BEDTOOLS_BLACKLIST {
    tag "${id}:${peak_type}"
    label 'process_low'
    container 'chipimage:latest'

    storeDir "${params.outdir}/${id}/peaks"

    input:
    tuple val(id), val(peak_type), path(peaks)
    path blacklist_bed

    output:
    tuple val(id), path("${id}_PeaksNoBL.bed"), emit: filtered_bed

    script:
    """
    bedtools intersect -v \\
        -a ${peaks} \\
        -b ${blacklist_bed} \\
        > ${id}_PeaksNoBL.bed
    """
}
