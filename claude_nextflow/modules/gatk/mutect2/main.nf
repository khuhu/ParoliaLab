/*
 * GATK_MUTECT2
 * Somatic variant calling in tumor-only mode.
 * Uses a panel of normals (PoN) and gnomAD germline resource to suppress
 * germline and artifact variants.
 */

nextflow.enable.dsl = 2

process GATK_MUTECT2 {
    tag "${meta.id}"
    label 'process_medium'

    publishDir "${params.outdir}/variant_calling/mutect2/${meta.id}", mode: 'copy',
        saveAs: { filename ->
            filename.endsWith('.raw.vcf.gz') ||
            filename.endsWith('.raw.vcf.gz.tbi') ||
            filename.endsWith('.raw.vcf.gz.stats') ? filename : null
        }

    input:
    tuple val(meta),
          path(bam),
          path(bai),
          path(ref),
          path(ref_fai),
          path(ref_dict),
          path(pon),
          path(pon_tbi),
          path(germline_resource),
          path(germline_resource_tbi)

    output:
    tuple val(meta),
          path("${meta.id}.raw.vcf.gz"),
          path("${meta.id}.raw.vcf.gz.tbi"),
          path("${meta.id}.raw.vcf.gz.stats"),
          emit: vcf

    script:
    // Mutect2 gets MaxDirectMemorySize=4G (vs 2G for other tools) because
    // native pair-HMM threads allocate off-heap memory per thread, which can
    // add up quickly and is the primary reason Mutect2 exceeds its stated heap.
    def xmx_gb = (task.memory.toGiga() * 0.80).intValue()
    def xms_gb = Math.max(4, (xmx_gb * 0.40).intValue())
    """
    gatk --java-options "-Xms${xms_gb}G -Xmx${xmx_gb}G \\
        -XX:+UseSerialGC \\
        -XX:ParallelGCThreads=2 \\
        -XX:MaxDirectMemorySize=4G" \\
        Mutect2 \\
        -R ${ref} \\
        -I ${bam} \\
        -tumor ${meta.id} \\
        --panel-of-normals ${pon} \\
        --germline-resource ${germline_resource} \\
        --native-pair-hmm-threads ${task.cpus} \\
        --af-of-alleles-not-in-resource 0.0000025 \\
        --tmp-dir ${params.tmp_dir} \\
        -O ${meta.id}.raw.vcf.gz
    """
}
