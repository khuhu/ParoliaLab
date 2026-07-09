process FASTQC {
    tag "${id}"
    label 'process_low'
    conda params.fastqc_env

    storeDir "${params.outdir}/${id}/fastqc"

    input:
    tuple val(id), path(r1), path(r2)

    output:
    tuple val(id), path("*_fastqc.html"), path("*_fastqc.zip"), emit: qc

    script:
    """
    fastqc -t ${task.cpus} ${r1} ${r2}
    """
}
