#! /bin/bash
echo $1
##Chip Data Pipelines....##
##8/31/21##
#Test edit 10/28
##docker build -t chipimage .
##docker run -idt -v /mctp/share/users/eleanoyo/NewDownload_54set_ChipSeq:/data -v /home/eleanoyo/REF:/data2 chipimage:latest /bin/bash
##docker ps
##docker attach [name]
##ref folder moved, now in mctp share drive, under eleanoyo/REF/hg38+path5_use
##If diff ref: java -jar /picard/build/libs/picard.jar CreateSequenceDictionary -R genome.fa -OUTPUT hg38.dict ##

##Trim data before running!##
## /home/eleanoyo/DockerSet/fastqcimage/Trimmomatic-0.39/trimmomatic-0.39.jar
## for i in /mctp/share/users/eleanoyo/NewDownload/input/*.fastq.gz; do java -jar trimmomatic-0.39.jar SE -threads 30 $i $i"Out.fq.gz" ILLUMINACLIP:/home/eleanoyo/DockerSet/fastqcimage/Trimmomatic-0.39/adapters/TruSeq3-SE.fa:2:30:10 MINLEN:30; done
												

prefix1=$1
#prefix2=basename $PWD 
input1=$prefix1"_1P.fq.gz"
input2=$prefix1"_2P.fq.gz"

#prefix1="${input1%%.*}"
echo $prefix1 "started. Using "$input1 "and" $input2 "as input" $(date) >> Log.log
bwa mem -5S -T0 -t5 /data2/genome.fa $input1 $input2 -o $prefix1"_aligned.sam" ## Human 
#bwa mem -5S -T0 -t5 /data2/mm10.fa $input1 $input2 -o $prefix1"_aligned.sam" ##Mouse adjust docker command reference too
samtools sort $prefix1"_aligned.sam" -o $prefix1"sorted_aligned.sam"
samtools view -hq 20 $prefix1"sorted_aligned.sam" -o $prefix1"filtered_sorted_aligned.sam"
wait -n;
echo "bwa finished..." $(date) >> Log.log;
java -jar /picard/build/libs/picard.jar MarkDuplicates -INPUT $prefix1"filtered_sorted_aligned.sam" -OUTPUT $prefix1"_aligned_PCRDupes.bam" -ASSUME_SORTED true -METRICS_FILE $prefix1"Aligned_Sorted_PCRDupes.txt" -VALIDATION_STRINGENCY SILENT ;
wait -n;
echo "picard finished..." $(date) >> Log.log;
samtools index $prefix1"_aligned_PCRDupes.bam"
wait -n;
samtools view -b -h -F 0x900 $prefix1"_aligned_PCRDupes.bam" | bedtools bamtobed -i stdin > $prefix1".primary.aln.bed"
#macs2 callpeak -t $prefix1".primary.aln.bed" -n $prefix1"OldMethod.macs2" -B
wait -n;
#macs2 callpeak -t $prefix1"_aligned_PCRDupes.bam" -f BAMPE -B -n $prefix1"BampeNoIGG_Narrow.macs2" #Narrow peaks for TFs
#macs2 callpeak -t $prefix1"_aligned_PCRDupes.bam" -f BAMPE -B --broad -n $prefix1"BampeNoIGG_Broad.macs2" #Broad for Histones
macs2 callpeak -t $prefix1"_aligned_PCRDupes.bam" -c /data2/SI_40572_VCaP_DMSO_IgG_aligned_PCRDupes.bam -f BAMPE -B -n $prefix1"BampeYesIgG_Narrow.macs2" #Narrow vcap IgG option for control , hg38 only; in hg38 ref folder
wait -n;
#mouse blacklist is mm10-blacklist.v2.Liftover.mm39.bed ; human is 
#bedtools intersect -v -a $prefix1"BampeNoIGG_Narrow.macs2_peaks.narrowPeak" -b /data2/FixBlacklist_ENCFF356LFX.bed > $prefix1"BampeNoIGG_NarrowPeakNoBL.bed"
#bedtools intersect -v -a $prefix1"BampeNoIGG_Broad.macs2_peaks.broadPeak" -b /data2/FixBlacklist_ENCFF356LFX.bed > $prefix1"BampeNoIGG_BroadPeakNoBL.bed"
bedtools intersect -v -a $prefix1"BampeYesIgG_Narrow.macs2_peaks.narrowPeak" -b /data2/FixBlacklist_ENCFF356LFX.bed > $prefix1"BampeYesIGG_NarrowPeakNoBL.bed"
wait -n;
echo "mac2 finished..." $(date) >> Log.log;
#Blacklist remove
#bedtools intersect -v -a $prefix1"BampeYesIgG_Narrow.macs2_peaks.narrowPeak" -b /data2/FixBlacklist_ENCFF356LFX.bed > $prefix1"OldMethod.NarrowPeakNoBL.bed"
wigToBigWig /data/$prefix1"BampeYesIgG_Narrow.macs2_treat_pileup.bdg" /data2/hg38.genome /data/$prefix1".bw" -clip
#Mouse: #wigToBigWig /data/$prefix1".macs2_treat_pileup.bdg" /data2/mm10.chrom.sizes /data/$prefix1".bw" -clip
echo "starting flagstat"
samtools view -Sb $prefix1"_aligned.sam" -o $prefix1"sorted_aligned.sam"
samtools flagstat $prefix1"sorted_aligned.sam" >> $prefix1"_flagstat.txt"
echo "DONE DONE DONE"
done
