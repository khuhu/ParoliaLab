/*
 * ARRIBA
 * Call gene fusions from a coordinate-sorted STAR BAM.
 * Indexes the BAM internally; no pre-existing .bai required.
 * Database files (blacklist, known fusions, protein domains) are resolved
 * from params.arriba_lib via glob — version-agnostic.
 *
 * Install: conda install -c bioconda arriba
 * Database path: $CONDA_PREFIX/share/arriba-*/
 */

process ARRIBA {
    tag "${meta.id}"
    label 'process_medium'

    publishDir "${params.outdir}/rna_processing/arriba/${meta.id}", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.fusions.tsv"),           emit: fusions
    tuple val(meta), path("${meta.id}.fusions.discarded.tsv"), emit: fusions_discarded

    script:
    """
    samtools index ${bam}

    blacklist=\$(ls ${params.arriba_lib}/blacklist_hg38_GRCh38_v*.tsv.gz)
    known=\$(ls ${params.arriba_lib}/known_fusions_hg38_GRCh38_v*.tsv.gz)
    domains=\$(ls ${params.arriba_lib}/protein_domains_hg38_GRCh38_v*.gff3)

    arriba \\
        -x ${bam} \\
        -o ${meta.id}.fusions.tsv \\
        -O ${meta.id}.fusions.discarded.tsv \\
        -a ${params.ref_hg38} \\
        -g ${params.gtf} \\
        -b \${blacklist} \\
        -k \${known} \\
        -p \${domains}
    """
}
