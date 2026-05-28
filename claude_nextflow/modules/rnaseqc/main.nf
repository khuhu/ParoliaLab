/*
 * RNASEQC
 * Compute RNA-seq quality metrics (coverage, expression correlation,
 * rRNA rate, etc.) using RNA-SeQC v2.
 *
 * --stranded rf: assume reverse-stranded library (adjust if needed)
 * -vv: verbose logging
 */

process RNASEQC {
    tag "${meta.id}"
    label 'process_low'

    publishDir "${params.outdir}/rna_processing/rnaseqc/${meta.id}", mode: 'copy',
        saveAs: { filename ->
            // Publish all RNA-SeQC output files
            filename.startsWith("${meta.id}/") ||
            filename.endsWith('.gct') ||
            filename.endsWith('.metrics.tsv') ||
            filename.endsWith('.exon_reads.gct') ? filename : filename
        }

    input:
    tuple val(meta),
          path(bam),
          path(bai),
          path(gtf)

    output:
    tuple val(meta), path("${meta.id}/${meta.id}.gene_reads.gct"),      emit: gene_counts
    tuple val(meta), path("${meta.id}/${meta.id}.metrics.tsv"),          emit: metrics
    tuple val(meta), path("${meta.id}/${meta.id}.exon_reads.gct"),       emit: exon_counts, optional: true

    script:
    """
    mkdir -p ${meta.id}

    rnaseqc \\
        ${gtf} \\
        ${bam} \\
        ${meta.id} \\
        -s ${meta.id} \\
        --stranded rf \\
        -vv
    """
}
