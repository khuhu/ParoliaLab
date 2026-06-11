process PICARD_MARKDUPLICATES {
    tag "${id}"
    label 'process_high_memory'
    container 'eleanoyo/chipimage:latest'

    publishDir "${params.outdir}/${id}/picard", mode: 'copy', pattern: "*.txt"

    input:
    tuple val(id), path(filtered_sam)

    output:
    tuple val(id), path("${id}_aligned_PCRDupes.bam"),      emit: bam
    path("${id}_Aligned_Sorted_PCRDupes.txt"),               emit: metrics

    script:
    """
    java -jar /picard/build/libs/picard.jar MarkDuplicates \\
        -INPUT ${filtered_sam} \\
        -OUTPUT ${id}_aligned_PCRDupes.bam \\
        -ASSUME_SORTED true \\
        -METRICS_FILE ${id}_Aligned_Sorted_PCRDupes.txt \\
        -VALIDATION_STRINGENCY SILENT
    echo "${id} picard finished \$(date)" >> Log.log
    """
}
