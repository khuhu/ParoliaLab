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
    raw_fastq_ch  // [sample_id, [r1_files], [r2_files]]

    main:
    def adapters    = Channel.fromPath(params.trimmomatic_adapters).first()
    def ref_dir     = Channel.fromPath(params.ref_dir).first()
    def igg_bam     = Channel.fromPath(params.igg_bam).first()
    def blacklist   = Channel.fromPath(params.blacklist_bed).first()
    def chrom_sizes = Channel.fromPath(params.chrom_sizes).first()

    MERGE_LANES(raw_fastq_ch)

    TRIMMOMATIC(MERGE_LANES.out.merged_fastq, adapters)

    BWA_ALIGN(TRIMMOMATIC.out.trimmed_fastq, ref_dir)

    SAMTOOLS_SORT_FILTER(BWA_ALIGN.out.sam)

    PICARD_MARKDUPLICATES(SAMTOOLS_SORT_FILTER.out.filtered_sam)

    SAMTOOLS_INDEX(PICARD_MARKDUPLICATES.out.bam)

    DEEPTOOLS_FINGERPRINT(SAMTOOLS_INDEX.out.indexed_bam, igg_bam)

    PHANTOMPEAKQUALTOOLS(SAMTOOLS_INDEX.out.indexed_bam)

    MACS2_CALLPEAK(SAMTOOLS_INDEX.out.indexed_bam, igg_bam)

    BEDTOOLS_BLACKLIST(MACS2_CALLPEAK.out.narrowpeak, blacklist)

    WIGTOBIGWIG(MACS2_CALLPEAK.out.bdg, chrom_sizes)

    SAMTOOLS_FLAGSTAT(PICARD_MARKDUPLICATES.out.bam)
}
