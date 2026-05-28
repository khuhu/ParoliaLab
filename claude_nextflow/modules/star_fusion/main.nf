/*
 * STAR_FUSION
 * Call gene fusions from STAR chimeric junction output.
 * Uses the pre-computed Chimeric.out.junction — no FASTQ re-processing needed.
 * Requires a CTAT genome library (separate from the STAR index):
 *   https://github.com/STAR-Fusion/STAR-Fusion/wiki
 * STAR must be run with --chimOutJunctionFormat 1.
 */

process STAR_FUSION {
    tag "${meta.id}"
    label 'process_high_memory'

    publishDir "${params.outdir}/rna_processing/star_fusion/${meta.id}", mode: 'copy'

    input:
    tuple val(meta), path(chimeric_junction)

    output:
    tuple val(meta), path("star-fusion.fusion_predictions.tsv"),          emit: fusions
    tuple val(meta), path("star-fusion.fusion_predictions.abridged.tsv"), emit: fusions_abridged

    script:
    """
    STAR-Fusion \\
        --genome_lib_dir ${params.star_fusion_lib} \\
        -J ${chimeric_junction} \\
        --output_dir . \\
        --CPU ${task.cpus}
    """
}
