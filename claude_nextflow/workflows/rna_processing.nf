/*
 * RNA Processing Workflow
 *
 * Steps:
 *   STAR_ALIGN → SAMTOOLS_SORT → PICARD_MARKDUPLICATES → RNASEQC
 *
 * Takes:  [meta, r1, r2]
 * Emits:  [meta, gene_counts_gct]
 */

include { STAR_ALIGN            } from '../modules/star/align/main'
include { SAMTOOLS_SORT         } from '../modules/samtools/sort/main'
include { PICARD_MARKDUPLICATES } from '../modules/picard/markduplicates/main'
include { RNASEQC               } from '../modules/rnaseqc/main'
include { STAR_FUSION           } from '../modules/star_fusion/main'

workflow RNA_PROCESSING {

    take:
    ch_reads  // [meta, r1, r2]

    main:

    // ── Align with STAR ───────────────────
    ch_star_input = ch_reads.map { meta, r1, r2 ->
        [meta, r1, r2, file(params.star_index, checkIfExists: true), file(params.gtf, checkIfExists: true)]
    }

    STAR_ALIGN(ch_star_input)

    // ── Fusion calling (parallel with BAM processing) ─────────────────────
    STAR_FUSION(STAR_ALIGN.out.chimeric_junctions)

    // ── Sort aligned BAM ──────────────────
    SAMTOOLS_SORT(STAR_ALIGN.out.bam)

    // ── Mark duplicates ───────────────────
    PICARD_MARKDUPLICATES(SAMTOOLS_SORT.out.bam)

    // ── RNA-SeQC quality metrics ──────────
    ch_rnaseqc_input = PICARD_MARKDUPLICATES.out.bam_bai
        .map { meta, bam, bai ->
            [meta, bam, bai, file(params.gtf, checkIfExists: true)]
        }

    RNASEQC(ch_rnaseqc_input)

    emit:
    gene_counts_gct = RNASEQC.out.gene_counts
    star_fusions    = STAR_FUSION.out.fusions
}
