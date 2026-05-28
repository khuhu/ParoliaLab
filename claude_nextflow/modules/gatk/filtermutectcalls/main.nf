/*
 * GATK_FILTERMUTECTCALLS
 * Apply Mutect2 artifact filters to produce a high-confidence somatic VCF.
 * Inputs include the raw VCF, its stats file, and the reference genome.
 */

nextflow.enable.dsl = 2

process GATK_FILTERMUTECTCALLS {
    tag "${meta.id}"
    label 'process_high_memory'

    publishDir "${params.outdir}/variant_calling/filtered/${meta.id}", mode: 'copy',
        saveAs: { filename ->
            filename.endsWith('.filtered.vcf.gz') ||
            filename.endsWith('.filtered.vcf.gz.tbi') ? filename : null
        }

    input:
    tuple val(meta),
          path(vcf),
          path(vcf_tbi),
          path(vcf_stats),
          path(ref),
          path(ref_fai)

    output:
    tuple val(meta),
          path("${meta.id}.filtered.vcf.gz"),
          path("${meta.id}.filtered.vcf.gz.tbi"),
          emit: vcf

    script:
    def xmx_gb = (task.memory.toGiga() * 0.80).intValue()
    def xms_gb = Math.max(4, (xmx_gb * 0.40).intValue())
    """
    gatk --java-options "-Xms${xms_gb}G -Xmx${xmx_gb}G \\
        -XX:+UseSerialGC \\
        -XX:ParallelGCThreads=2 \\
        -XX:MaxDirectMemorySize=2G" \\
        FilterMutectCalls \\
        -R ${ref} \\
        -V ${vcf} \\
        --stats ${vcf_stats} \\
        --tmp-dir ${params.tmp_dir} \\
        -O ${meta.id}.filtered.vcf.gz
    """
}
