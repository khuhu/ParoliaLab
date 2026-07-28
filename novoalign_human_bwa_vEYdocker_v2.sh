set -e

###
export ID=$1
export FLOWCELL=$2
mkdir -p $ID/bam/reports
mkdir -p $ID/macs2/

#forHumanReferenceGenome_GRCh38 using BWA aligner
echo 
echo "########## $ID: pre-processing ##########"
date 
##export FILE1=/data/mctp_SI_$ID"_"*"_1.fq.gz"
##export FILE2=/data/mctp_SI_$ID"_"*"_2.fq.gz"
#export FILE1=/data/$ID"_2_R1.fq.gz"
#export FILE2=/data/$ID"_2_R2.fq.gz"
export FILE1=/data/$ID"_R1_val_1.fq.gz"
export FILE2=/data/$ID"_R2_val_2.fq.gz"
echo $FILE1
echo $FILE2
nomenF="$(basename $FILE1 _1.fq.gz)"
echo "STEP1 ######## $SAMPLE: BWA ########"
echo "bwa command:"
echo ""
bwa mem -t 5 /data2/genome.fa $FILE1 $FILE2 > $ID/bam/${nomenF}.sam
echo
echo "STEP2 ######## $ID: Bam process ########"
samtools sort  -@ 5 $ID/bam/${nomenF}.sam -o $ID/bam/${nomenF}_sort.bam
samtools index $ID/bam/${nomenF}_sort.bam
samtools flagstat $ID/bam/${nomenF}_sort.bam > $ID/bam/reports/${nomenF}_sort_flagstat.txt
samtools idxstats $ID/bam/${nomenF}_sort.bam > $ID/bam/reports/${nomenF}_sort_idxstats.txt
#grep 'chrM' $ID/bam/reports/${nomenF}_sort_idxstats.txt | cut -f3
java -jar /picard/build/libs/picard.jar CollectInsertSizeMetrics I=$ID/bam/${nomenF}_sort.bam O=$ID/bam/reports/${nomenF}_size.txt H=$ID/bam/reports/${nomenF}_size.pdf
echo
echo "STEP3 ######## $ID: Bam filtering ########"
gzip -c $ID/bam/${nomenF}.sam > $ID/bam/${nomenF}.sam.gz
zcat $ID/bam/${nomenF}.sam.gz | sed '/chrM/d' | samtools view -bS -@ 5 - | samtools sort -@ 5 - -o $ID/bam/${nomenF}_nochrM_sort.bam
samtools index $ID/bam/${nomenF}_nochrM_sort.bam
samtools flagstat $ID/bam/${nomenF}_nochrM_sort.bam > $ID/bam/reports/${nomenF}_nochrM_sort_flagstat.txt
samtools idxstats $ID/bam/${nomenF}_nochrM_sort.bam > $ID/bam/reports/${nomenF}_nochrM_sort_idxstats.txt
java -jar /picard/build/libs/picard.jar MarkDuplicates I=$ID/bam/${nomenF}_nochrM_sort.bam O=$ID/bam/${nomenF}_nochrM_sort_rmd.bam REMOVE_DUPLICATES=true ASSUME_SORTED=true M=$ID/bam/reports/${nomenF}_nochrM_sort_rmd.txt CREATE_INDEX=true 
samtools flagstat $ID/bam/${nomenF}_nochrM_sort_rmd.bam > $ID/bam/reports/${nomenF}_nochrM_sort_rmd_flagstat.txt
samtools idxstats $ID/bam/${nomenF}_nochrM_sort_rmd.bam > $ID/bam/reports/${nomenF}_nochrM_sort_rmd_idxstats.txt
echo
echo "STEP4 ######## $ID: macs2 peak calling ########"
macs2 callpeak -t $ID/bam/${nomenF}_nochrM_sort_rmd.bam  -n $ID/macs2/${nomenF}_macs2 -g hs -f BAMPE -B -q 0.001 --nolambda --SPMR 2> $ID/macs2/${nomenF}_macs2.out
wigToBigWig $ID/macs2/*treat* /data2/hg38.genome $ID/${nomenF}_macs2_treat_pileup.bw 
echo
echo "######## $ID: Completed ########"



