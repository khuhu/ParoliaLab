/*
 * GATK_FUNCOTATOR
 * Functionally annotate somatic variants using GATK Funcotator.
 * Produces MAF format output (hg38 reference version).
 */

nextflow.enable.dsl = 2

process GATK_FUNCOTATOR {
    tag "${meta.id}"
    label 'process_high_memory'

    publishDir "${params.outdir}/variant_calling/funcotator/${meta.id}", mode: 'copy',
        saveAs: { filename ->
            filename.endsWith('.maf') || filename.endsWith('.maf.gz') ? filename : null
        }

    input:
    tuple val(meta),
          path(vcf),
          path(vcf_tbi),
          path(ref),
          path(ref_fai),
          path(funcotator_data)

    output:
    tuple val(meta), path("${meta.id}.maf"), emit: maf

    script:
    def xmx_gb = (task.memory.toGiga() * 0.80).intValue()
    def xms_gb = Math.max(4, (xmx_gb * 0.40).intValue())
    """
    gatk --java-options "-Xms${xms_gb}G -Xmx${xmx_gb}G \\
        -XX:+UseSerialGC \\
        -XX:ParallelGCThreads=2 \\
        -XX:MaxDirectMemorySize=2G" \\
        Funcotator \\
        -R ${ref} \\
        -V ${vcf} \\
        --data-sources-path ${funcotator_data} \\
        --ref-version hg38 \\
        --output-file-format MAF \\
        --tmp-dir ${params.tmp_dir} \\
        -O ${meta.id}.maf
    """
}
