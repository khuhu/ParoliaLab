/*
 * SAMTOOLS_ADDREPLACERG
 * Add or replace read group (@RG) headers in a BAM file,
 * then index the result.
 * This ensures GATK tools see a compliant RG header.
 */

nextflow.enable.dsl = 2

process SAMTOOLS_ADDREPLACERG {
    tag "${meta.id}"
    label 'process_low'

    publishDir "${params.outdir}/dna_preprocessing/rg/${meta.id}", mode: 'copy',
        saveAs: { filename -> filename.endsWith('.rg.bam') || filename.endsWith('.bai') ? filename : null }

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}.rg.bam"), path("${meta.id}.rg.bam.bai"), emit: bam_bai

    script:
    """
    samtools addreplacerg \\
        -r '@RG\\tID:${meta.id}\\tSM:${meta.id}\\tPL:ILLUMINA\\tLB:${meta.id}\\tPU:${meta.id}' \\
        -o ${meta.id}.rg.bam \\
        ${bam}

    samtools index \\
        -@ ${task.cpus} \\
        ${meta.id}.rg.bam
    """
}
