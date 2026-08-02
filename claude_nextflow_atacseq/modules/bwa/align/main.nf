process BWA_ALIGN {
    tag "${id}"
    label 'process_high'
    container 'chipimage:latest'

    storeDir "${params.outdir}/${id}/bwa"

    input:
    tuple val(id), path(r1), path(r2)
    path ref_dir

    output:
    tuple val(id), path("${id}_aligned.sam"), emit: sam

    script:
    """
    bwa mem -t ${task.cpus} -R "@RG\\tID:${id}\\tSM:${id}\\tLB:${id}\\tPL:ILLUMINA" ${ref_dir}/genome.fa ${r1} ${r2} -o ${id}_aligned.sam
    """
}
