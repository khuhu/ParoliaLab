process SAMTOOLS_IDXSTATS {
    tag "${id}"
    label 'process_low'
    container 'atacimage:latest'

    storeDir "${params.outdir}/${id}/reports"

    input:
    tuple val(id), path(bam), path(bai)

    output:
    tuple val(id), path("${bam.baseName}_idxstats.txt"), emit: idxstats

    script:
    """
    samtools idxstats ${bam} > ${bam.baseName}_idxstats.txt
    """
}
