/*
 * SAMTOOLS_INDEX
 * Index a coordinate-sorted BAM file (produces .bai).
 */

nextflow.enable.dsl = 2

process SAMTOOLS_INDEX {
    tag "${meta.id}"
    label 'process_low'

    publishDir "${params.outdir}/dna_preprocessing/sorted/${meta.id}", mode: 'copy',
        saveAs: { filename -> filename.endsWith('.bai') ? filename : null }

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${bam}.bai"), emit: bai

    script:
    """
    samtools index \\
        -@ ${task.cpus} \\
        ${bam}
    """
}
