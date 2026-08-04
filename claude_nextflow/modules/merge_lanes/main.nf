/*
 * MERGE_LANES
 * Concatenate per-lane FASTQs into a single R1/R2 file per sample.
 * Mirrors the MERGE_LANES step in the ChipSeq/ATAC-seq pipelines.
 */

process MERGE_LANES {
    tag "${meta.id}"
    label 'process_low'

    storeDir "${params.outdir}/rna_processing/fastq_merged/${meta.id}"

    input:
    tuple val(meta), path(r1_files), path(r2_files)

    output:
    tuple val(meta), path("${meta.id}_R1.fq.gz"), path("${meta.id}_R2.fq.gz"), emit: merged_fastq

    script:
    """
    cat ${r1_files} > ${meta.id}_R1.fq.gz
    cat ${r2_files} > ${meta.id}_R2.fq.gz
    """
}
