process WIGTOBIGWIG {
    tag "${id}"
    label 'process_medium'
    container 'chipimage:latest'

    storeDir "${params.outdir}/${id}/bigwig"

    input:
    tuple val(id), path(bdg)
    path chrom_sizes

    output:
    tuple val(id), path("${id}.bw"), emit: bigwig

    script:
    """
    wigToBigWig ${bdg} ${chrom_sizes} ${id}.bw -clip
    """
}
