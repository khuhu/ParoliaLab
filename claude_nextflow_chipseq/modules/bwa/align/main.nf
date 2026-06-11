// ref_dir is mounted as /data2 via containerOptions in nextflow.config
process BWA_ALIGN {
    tag "${id}"
    label 'process_high'
    container 'eleanoyo/chipimage:latest'

    input:
    tuple val(id), path(r1), path(r2)

    output:
    tuple val(id), path("${id}_aligned.sam"), emit: sam

    script:
    """
    bwa mem -5S -T0 -t ${task.cpus} /data2/genome.fa ${r1} ${r2} -o ${id}_aligned.sam
    echo "${id} bwa finished \$(date)" >> Log.log
    """
}
