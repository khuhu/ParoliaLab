process BEDTOOLS_BLACKLIST {
    tag "${id}"
    label 'process_low'
    container 'eleanoyo/chipimage:latest'

    publishDir { "${params.outdir}/${id}/peaks" }, mode: 'copy'

    input:
    tuple val(id), path(narrowpeak)
    path blacklist_bed

    output:
    tuple val(id), path("${id}_NarrowPeakNoBL.bed"), emit: filtered_bed

    script:
    """
    bedtools intersect -v \\
        -a ${narrowpeak} \\
        -b ${blacklist_bed} \\
        > ${id}_NarrowPeakNoBL.bed
    """
}
