#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { MERGE_LANES                                     } from '../modules/merge_lanes/main.nf'
include { BWA_ALIGN                                        } from '../modules/bwa/align/main.nf'
include { SAMTOOLS_SORT                                    } from '../modules/samtools/sort/main.nf'
include { SAMTOOLS_INDEX    as SAMTOOLS_INDEX_SORT         } from '../modules/samtools/index/main.nf'
include { SAMTOOLS_INDEX    as SAMTOOLS_INDEX_NOCHRM       } from '../modules/samtools/index/main.nf'
include { SAMTOOLS_FLAGSTAT as SAMTOOLS_FLAGSTAT_SORT      } from '../modules/samtools/flagstat/main.nf'
include { SAMTOOLS_FLAGSTAT as SAMTOOLS_FLAGSTAT_NOCHRM    } from '../modules/samtools/flagstat/main.nf'
include { SAMTOOLS_FLAGSTAT as SAMTOOLS_FLAGSTAT_RMD       } from '../modules/samtools/flagstat/main.nf'
include { SAMTOOLS_IDXSTATS as SAMTOOLS_IDXSTATS_SORT      } from '../modules/samtools/idxstats/main.nf'
include { SAMTOOLS_IDXSTATS as SAMTOOLS_IDXSTATS_NOCHRM    } from '../modules/samtools/idxstats/main.nf'
include { SAMTOOLS_IDXSTATS as SAMTOOLS_IDXSTATS_RMD       } from '../modules/samtools/idxstats/main.nf'
include { PICARD_COLLECTINSERTSIZEMETRICS                 } from '../modules/picard/collectinsertsizemetrics/main.nf'
include { REMOVE_CHRM                                      } from '../modules/samtools/remove_chrm/main.nf'
include { PICARD_MARKDUPLICATES                            } from '../modules/picard/markduplicates/main.nf'
include { MACS2_CALLPEAK                                   } from '../modules/macs2/callpeak/main.nf'
include { WIGTOBIGWIG                                       } from '../modules/ucsc/wigtobigwig/main.nf'

workflow ATACSEQ_PROCESSING {
    take:
    raw_fastq_ch  // [sample_id, [r1_files], [r2_files]]

    main:
    def ref_dir     = Channel.fromPath(params.ref_dir).first()
    def chrom_sizes = Channel.fromPath(params.chrom_sizes).first()

    MERGE_LANES(raw_fastq_ch)

    BWA_ALIGN(MERGE_LANES.out.merged_fastq, ref_dir)

    // Raw sorted BAM: index/flagstat/idxstats + insert-size QC
    SAMTOOLS_SORT(BWA_ALIGN.out.sam)
    SAMTOOLS_INDEX_SORT(SAMTOOLS_SORT.out.bam)
    SAMTOOLS_FLAGSTAT_SORT(SAMTOOLS_SORT.out.bam)
    SAMTOOLS_IDXSTATS_SORT(SAMTOOLS_INDEX_SORT.out.indexed_bam)
    PICARD_COLLECTINSERTSIZEMETRICS(SAMTOOLS_SORT.out.bam)

    // Drop mitochondrial reads, then QC the filtered BAM
    REMOVE_CHRM(BWA_ALIGN.out.sam)
    SAMTOOLS_INDEX_NOCHRM(REMOVE_CHRM.out.bam)
    SAMTOOLS_FLAGSTAT_NOCHRM(REMOVE_CHRM.out.bam)
    SAMTOOLS_IDXSTATS_NOCHRM(SAMTOOLS_INDEX_NOCHRM.out.indexed_bam)

    // Remove PCR duplicates (Picard creates its own index), then QC + peak call
    PICARD_MARKDUPLICATES(REMOVE_CHRM.out.bam)
    rmd_bam_ch = PICARD_MARKDUPLICATES.out.bam_bai.map { id, bam, bai -> tuple(id, bam) }

    SAMTOOLS_FLAGSTAT_RMD(rmd_bam_ch)
    SAMTOOLS_IDXSTATS_RMD(PICARD_MARKDUPLICATES.out.bam_bai)

    MACS2_CALLPEAK(rmd_bam_ch)

    WIGTOBIGWIG(MACS2_CALLPEAK.out.bdg, chrom_sizes)
}
