/*
 * STAR_ALIGN
 * Align RNA-seq reads using STAR with GTEx-compatible parameters.
 * Features: two-pass mode, chimeric read detection, gene count quantification,
 * transcriptome BAM for downstream tools, unsorted BAM output.
 */

process STAR_ALIGN {
    tag "${meta.id}"
    label 'process_medium'

    publishDir "${params.outdir}/rna_processing/star/${meta.id}", mode: 'copy',
        saveAs: { filename ->
            filename.endsWith('Aligned.out.bam') ||
            filename.endsWith('Aligned.toTranscriptome.out.bam') ||
            filename.endsWith('Chimeric.out.junction') ||
            filename.endsWith('ReadsPerGene.out.tab') ||
            filename.endsWith('Log.final.out') ||
            filename.endsWith('Log.out') ||
            filename.endsWith('Log.progress.out') ||
            filename.endsWith('SJ.out.tab') ? filename : null
        }

    input:
    tuple val(meta),
          path(r1),
          path(r2),
          path(star_index),
          path(gtf)

    output:
    tuple val(meta), path("${meta.id}Aligned.out.bam"),                 emit: bam
    tuple val(meta), path("${meta.id}Aligned.toTranscriptome.out.bam"), emit: transcriptome_bam
    tuple val(meta), path("${meta.id}ReadsPerGene.out.tab"),            emit: gene_counts
    tuple val(meta), path("${meta.id}Chimeric.out.junction"),           emit: chimeric_junctions
    tuple val(meta), path("${meta.id}Log.final.out"),                   emit: log_final
    tuple val(meta), path("${meta.id}Log.out"),                         emit: log_out
    tuple val(meta), path("${meta.id}Log.progress.out"),                emit: log_progress
    tuple val(meta), path("${meta.id}SJ.out.tab"),                      emit: sj_tab

    script:
    """
    STAR \\
        --runMode alignReads \\
        --runThreadN ${task.cpus} \\
        --genomeDir ${star_index} \\
        --sjdbGTFfile ${gtf} \\
        --readFilesIn ${r1} ${r2} \\
        --readFilesCommand zcat \\
        --twopassMode Basic \\
        --outSAMtype BAM Unsorted \\
        --outSAMattributes NH HI AS nM NM ch \\
        --outSAMattrRGline ID:rg1 SM:sm1 \\
        --outSAMstrandField intronMotif \\
        --outFilterIntronMotifs None \\
        --alignSoftClipAtReferenceEnds Yes \\
        --quantMode TranscriptomeSAM GeneCounts \\
        --outFilterMultimapNmax 20 \\
        --alignSJoverhangMin 8 \\
        --alignSJDBoverhangMin 1 \\
        --outFilterMismatchNmax 999 \\
        --outFilterMismatchNoverLmax 0.1 \\
        --alignIntronMin 20 \\
        --alignIntronMax 1000000 \\
        --alignMatesGapMax 1000000 \\
        --outFilterType BySJout \\
        --outFilterScoreMinOverLread 0.33 \\
        --outFilterMatchNminOverLread 0.33 \\
        --limitSjdbInsertNsj 1200000 \\
        --chimSegmentMin 15 \\
        --chimJunctionOverhangMin 15 \\
        --chimOutType Junctions WithinBAM SoftClip \\
        --chimMainSegmentMultNmax 1 \\
        --chimOutJunctionFormat 1 \\
        --outFileNamePrefix ${meta.id}
    """
}
