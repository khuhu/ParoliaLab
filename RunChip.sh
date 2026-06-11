#Date:
#reference:
#Run Folder:

#Find and replace the list of samples,
#SI_43222_VCaP_DXL_DMSO_GR SI_43223_VCaP_DXL_100nM_JZY3032_3h_GR SI_43224_VCaP_DXL__DMSO_PR SI_43225_VCaP_DXL_100nM_JZY3032_3h_PR SI_43226_VCaP_DXL_DMSO_SRC2 SI_43227_VCaP_DXL_100nM_JZY3032_3h_SRC2 SI_43228_VCaP_DXL_DMSO_CBP SI_43229_VCaP_DXL_100nM_JZY3032_3h_CBP 

#set your folder,
folder1=Jie_DXL_March30_HHH3HDRX7
#echo "gsutil -m cp " >> Fetch.sh
#for i in {43222..43229} 
#do gsutil ls gs://mctp-fastq/** | grep SI_$i >> Fetch.sh
#done

#gsutil ls gs://mctp-fastq/** | grep SI_34830 >> Fetch.sh


#Merge lanes: (skip if already merged)
for file in *_SI_*_*_*_1.fq.gz
do echo $file
new_name=${file#*_}
new_name=${new_name%_*_*_1.fq.gz}
cat "$file">>./${new_name}_R1.fq.gz
done
for file in *_SI_*_*_*_2.fq.gz
do new_name=${file#*_}
new_name=${new_name%_*_*_2.fq.gz}
cat "$file">>./${new_name}_R2.fq.gz
done


#Use excel template to make if statements in the below section: 
for i in SI_43222 SI_43223 SI_43224 SI_43225 SI_43226 SI_43227 SI_43228 SI_43229
do echo $i
if [[ "$i" == "SI_43222" ]]; then name1=SI_43222_VCaP_DXL_DMSO_GR
elif [[ "$i" == "SI_43223" ]]; then name1=SI_43223_VCaP_DXL_100nM_JZY3032_3h_GR
elif [[ "$i" == "SI_43224" ]]; then name1=SI_43224_VCaP_DXL__DMSO_PR
elif [[ "$i" == "SI_43225" ]]; then name1=SI_43225_VCaP_DXL_100nM_JZY3032_3h_PR
elif [[ "$i" == "SI_43226" ]]; then name1=SI_43226_VCaP_DXL_DMSO_SRC2
elif [[ "$i" == "SI_43227" ]]; then name1=SI_43227_VCaP_DXL_100nM_JZY3032_3h_SRC2
elif [[ "$i" == "SI_43228" ]]; then name1=SI_43228_VCaP_DXL_DMSO_CBP
elif [[ "$i" == "SI_43229" ]]; then name1=SI_43229_VCaP_DXL_100nM_JZY3032_3h_CBP
fi
f1=$i"_R1.fq.gz"
f2=$i"_R2.fq.gz"
#nohup java -jar /home/eleanoyo/DockerSet/fastqcimage/Trimmomatic-0.39/trimmomatic-0.39.jar PE -threads 5 $f1 $f2 -baseout $name1".fq.gz" ILLUMINACLIP:/home/eleanoyo/DockerSet/fastqcimage/Trimmomatic-0.39/adapters/TruSeq3-PE-2.fa:2:30:10 MINLEN:50 > $name1.out 2>&1 &
nohup java -jar /mctp/share/users/eleanoyo/Software/Trimmomatic-0.39/Trimmomatic-0.39/trimmomatic-0.39.jar PE -threads 5 $f1 $f2 -baseout $name1".fq.gz" ILLUMINACLIP:/mctp/share/users/eleanoyo/Software/trimmomatic/adapters/TruSeq3-PE-2.fa:2:30:10 MINLEN:50 >LogTRIM$name1.log 2>&1 &
done

############## wait here for trimming to finish, htop to monitor ############################

############# once trimming done, ############################ 

#Trim Stats
for i in *.log; do grep --with-filename Surviving $i | xargs>>Cat.txt; done
sed "s/:\|(/\t/g" Cat.txt > Cat2.txt
sed 's/\(Input Read Pairs\)\|\( Both Surviving\)\|\( Forward Only Surviving\)\|\( Reverse Only Surviving\)\|\( Dropped\)//g' Cat2.txt > Cat3.txt
echo -e "Sample\tBlank\tInput Pairs\tBothSurviving\t%\tForwardOnly\t%\tReverseOnly\t%\tDropped\t%\tblank">TrimStats.txt;
 cat Cat3.txt >>TrimStats.txt
sed "s/ \|)//g" TrimStats.txt > TrimStats2.txt
rm TrimStats.txt Cat3.txt 


#Move fastqs and scripts into subfolders 
for i in  SI_43222_VCaP_DXL_DMSO_GR SI_43223_VCaP_DXL_100nM_JZY3032_3h_GR SI_43224_VCaP_DXL__DMSO_PR SI_43225_VCaP_DXL_100nM_JZY3032_3h_PR SI_43226_VCaP_DXL_DMSO_SRC2 SI_43227_VCaP_DXL_100nM_JZY3032_3h_SRC2 SI_43228_VCaP_DXL_DMSO_CBP SI_43229_VCaP_DXL_100nM_JZY3032_3h_CBP
do echo $i
mkdir $i
cp /mctp/share/users/eleanoyo/Datasets/ChipSeq/$folder1/ChipPipe_v3_PE.sh ./$i
mv $i*1P.fq.gz ./$i/
mv  $i*2P.fq.gz ./$i/
done

mkdir unpaired
mv *U.fq.gz ./unpaired/
mkdir raw
mv mctp*.fq.gz ./raw/
mkdir flag 

#Launch Dockers and scripts 
## You will need to add -u {uid} if using my image, else it will run under my name, id -u to get your number 
for i in SI_43222_VCaP_DXL_DMSO_GR SI_43223_VCaP_DXL_100nM_JZY3032_3h_GR SI_43224_VCaP_DXL__DMSO_PR SI_43225_VCaP_DXL_100nM_JZY3032_3h_PR SI_43226_VCaP_DXL_DMSO_SRC2 SI_43227_VCaP_DXL_100nM_JZY3032_3h_SRC2 SI_43228_VCaP_DXL_DMSO_CBP SI_43229_VCaP_DXL_100nM_JZY3032_3h_CBP 
do echo $i
echo "cd /data; ./ChipPipe_v3_PE.sh $i"
docker run -idt -v /mctp/share/users/eleanoyo/REF/hg38_path5_USE:/data2 -v /mctp/share/users/eleanoyo/Datasets/ChipSeq/$folder1/$i:/data --name $i eleanoyo/chipimage:latest /bin/bash
docker attach $i
done

######## Wait here for runs to finish. Htop to monitor ##################### 

########################### Once all runs in each docker finished, ######################3
mkdir bigwigs
mkdir bed
find -name *bw | xargs cp -t ./bigwigs/
find -name *NoBL.bed | xargs cp -t ./bed/


for i in SI_43222_VCaP_DXL_DMSO_GR SI_43223_VCaP_DXL_100nM_JZY3032_3h_GR SI_43224_VCaP_DXL__DMSO_PR SI_43225_VCaP_DXL_100nM_JZY3032_3h_PR SI_43226_VCaP_DXL_DMSO_SRC2 SI_43227_VCaP_DXL_100nM_JZY3032_3h_SRC2 SI_43228_VCaP_DXL_DMSO_CBP SI_43229_VCaP_DXL_100nM_JZY3032_3h_CBP
do awk '{print FILENAME"\t"$0}' ./$i/$i"Aligned_Sorted_PCRDupes.txt" >> CombinedDupstat.txt
done
grep Unknown CombinedDupstat.txt >> Hg38_DupStats.txt
rm CombinedDupstat.txt 


#Flagstat
mkdir flag
for i in SI_43222_VCaP_DXL_DMSO_GR SI_43223_VCaP_DXL_100nM_JZY3032_3h_GR SI_43224_VCaP_DXL__DMSO_PR SI_43225_VCaP_DXL_100nM_JZY3032_3h_PR SI_43226_VCaP_DXL_DMSO_SRC2 SI_43227_VCaP_DXL_100nM_JZY3032_3h_SRC2 SI_43228_VCaP_DXL_DMSO_CBP SI_43229_VCaP_DXL_100nM_JZY3032_3h_CBP
do echo $i 
cp ./$i/$i"_flagstat.txt" ./flag/ 
done
cd flag
for f in *; do
[ -f "$f" ] && [ ! -L "$f" ] && printf '%s\n' "${f%.*}" >> "$f"
done
ls >tmp.txt
awk '$1=$1' ORS=' ' tmp.txt > tmp2.txt
head tmp2.txt #c/p this line output after paste below, pipe to Flagstat.txt
paste 
> FlagStat.txt 
#excel =left(B1, find("+",B1,1)-2) to keep only first part as numbers ....




###Wrap up ###
#Check bigwigs with beds in IGV
#Save the stats txts together into an excel
#make sure the flowcell sheet and lims info sheet saved in folder as well 



