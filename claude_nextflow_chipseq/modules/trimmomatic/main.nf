process TRIMMOMATIC {
    tag "${id}"
    label 'process_medium'
    conda '/mctp/share/users/kevhu/miniconda3/envs/trimmomatic_env'

    publishDir { "${params.outdir}/${id}/trimmomatic" }, mode: 'copy', pattern: "*.log"

    input:
    tuple val(id), path(r1), path(r2)
    path adapters

    output:
    tuple val(id), path("${id}_1P.fq.gz"), path("${id}_2P.fq.gz"), emit: trimmed_fastq
    path("${id}_trim.log"),                                          emit: log

    script:
    """
    trimmomatic PE -threads ${task.cpus} \\
        ${r1} ${r2} \\
        -baseout ${id}.fq.gz \\
        ILLUMINACLIP:${adapters}:2:30:10 MINLEN:50 \\
        > ${id}_trim.log 2>&1
    """
}
