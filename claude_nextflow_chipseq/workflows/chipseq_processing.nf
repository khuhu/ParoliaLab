#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { MERGE_LANES           } from '../modules/merge_lanes/main.nf'
include { TRIMMOMATIC           } from '../modules/trimmomatic/main.nf'
include { BWA_ALIGN             } from '../modules/bwa/align/main.nf'
include { SAMTOOLS_SORT_FILTER  } from '../modules/samtools/sort_filter/main.nf'
include { PICARD_MARKDUPLICATES } from '../modules/picard/markduplicates/main.nf'
include { SAMTOOLS_INDEX        } from '../modules/samtools/index/main.nf'
include { MACS2_CALLPEAK        } from '../modules/macs2/callpeak/main.nf'
include { BEDTOOLS_BLACKLIST    } from '../modules/bedtools/blacklist_filter/main.nf'
include { WIGTOBIGWIG           } from '../modules/ucsc/wigtobigwig/main.nf'
include { SAMTOOLS_FLAGSTAT     } from '../modules/samtools/flagstat/main.nf'
include { DEEPTOOLS_FINGERPRINT } from '../modules/deeptools/fingerprint/main.nf'
include { PHANTOMPEAKQUALTOOLS  } from '../modules/phantompeakqualtools/main.nf'

workflow CHIPSEQ_PROCESSING {
    take:
    raw_fastq_ch  // [sample_id, peak_type, [r1_files], [r2_files]]

    main:
    def adapters    = Channel.fromPath(params.trimmomatic_adapters).first()
    def ref_dir     = Channel.fromPath(params.ref_dir).first()
    def igg_bam     = Channel.fromPath(params.igg_bam).first()
    def igg_bai     = Channel.fromPath(params.igg_bai).first()
    def blacklist   = Channel.fromPath(params.blacklist_bed).first()
    def chrom_sizes = Channel.fromPath(params.chrom_sizes).first()

    // Split peak_type into its own channel; intermediate modules only need [id, ...]
    peak_type_ch = raw_fastq_ch.map { id, peak_type, r1, r2 -> tuple(id, peak_type) }
    fastq_ch     = raw_fastq_ch.map { id, peak_type, r1, r2 -> tuple(id, r1, r2) }

    MERGE_LANES(fastq_ch)

    TRIMMOMATIC(MERGE_LANES.out.merged_fastq, adapters)

    BWA_ALIGN(TRIMMOMATIC.out.trimmed_fastq, ref_dir)

    SAMTOOLS_SORT_FILTER(BWA_ALIGN.out.sam)

    PICARD_MARKDUPLICATES(SAMTOOLS_SORT_FILTER.out.filtered_sam)

    SAMTOOLS_INDEX(PICARD_MARKDUPLICATES.out.bam)

    DEEPTOOLS_FINGERPRINT(SAMTOOLS_INDEX.out.indexed_bam, igg_bam, igg_bai)

    PHANTOMPEAKQUALTOOLS(SAMTOOLS_INDEX.out.indexed_bam)

    SAMTOOLS_FLAGSTAT(PICARD_MARKDUPLICATES.out.bam)

    // Rejoin peak_type before MACS2
    macs2_input = SAMTOOLS_INDEX.out.indexed_bam
        .join(peak_type_ch)
        .map { id, bam, bai, peak_type -> tuple(id, peak_type, bam, bai) }

    MACS2_CALLPEAK(macs2_input, igg_bam)

    BEDTOOLS_BLACKLIST(MACS2_CALLPEAK.out.peaks, blacklist)

    WIGTOBIGWIG(MACS2_CALLPEAK.out.bdg, chrom_sizes)
}
