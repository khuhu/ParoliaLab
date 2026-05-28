/*
 * SAMTOOLS_SORT
 * Sort a BAM file by coordinate.
 * Used for both DNA (post-BWA) and RNA (post-STAR) BAMs.
 */

process SAMTOOLS_SORT {
    tag "${meta.id}"
    label 'process_high'

    publishDir "${params.outdir}/rna_processing/sorted/${meta.id}", mode: 'copy',
        saveAs: { filename ->
            // Only publish the sorted BAM if it's a final intermediate;
            // downstream steps will overwrite with their own publishDir.
            filename.endsWith('.sorted.bam') ? filename : null
        }

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), emit: bam

    script:
    """
    samtools sort \\
        -@ ${task.cpus} \\
        -m 2G \\
        -T ${params.tmp_dir}/${meta.id}_sort_tmp \\
        -o ${meta.id}.sorted.bam \\
        ${bam}
    """
}
