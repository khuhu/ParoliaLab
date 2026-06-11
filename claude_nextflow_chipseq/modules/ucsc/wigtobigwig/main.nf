// ref_dir is mounted as /data2 via containerOptions in nextflow.config
// chrom_sizes is also passed as a staged input for flexibility
process WIGTOBIGWIG {
    tag "${id}"
    label 'process_low'
    container 'eleanoyo/chipimage:latest'

    publishDir "${params.outdir}/${id}/bigwig", mode: 'copy'

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
