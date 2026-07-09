process BEDTOOLS_PBC {
    tag "${id}"
    label 'process_low'
    container 'chipimage:latest'

    storeDir "${params.outdir}/${id}/pbc"

    input:
    tuple val(id), path(filtered_sam)

    output:
    tuple val(id), path("${id}_pbc.txt"), emit: pbc

    script:
    """
    samtools view -F 0x0204 -b ${filtered_sam} \\
        | bedtools bamtobed -i stdin \\
        | awk 'BEGIN{OFS="\\t"} {print \$1,\$2,\$3,\$6}' \\
        | sort | uniq -c \\
        | awk 'BEGIN{mt=0;m0=0;m1=0}
               {mt=mt+\$1; m0=m0+1; if(\$1==1) m1=m1+1}
               END{
                 printf "TotalReadPairs\\t%d\\nDistinctPositions\\t%d\\nOneReadPositions\\t%d\\nNRF\\t%f\\nPBC1\\t%f\\n",
                 mt, m0, m1, m0/mt, m1/m0
               }' > ${id}_pbc.txt
    """
}
