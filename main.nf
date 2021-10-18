#!/usr/bin/env nextflow


sequences1='s3://transcriptomepipeline/Physaria_Lind_R1.fastq.gz'
sequences12='s3://transcriptomepipeline/Physaria_Lind_R2.fastq.gz'
sequences2='s3://transcriptomepipeline/ContaminantsForRemove.fasta'
sequences22='s3://transcriptomepipeline/ContaminantsForRemove.fasta'
adapters='s3://transcriptomepipeline/TruSeq3-PE.fa'
pairInt='s3://transcriptomepipeline/PairInterleaves.sh'
/*
process minimapS31 {

	memory '16G'
	input:
	path fastq from sequences1
	path contam from sequences2
	
	output:
	file 'aln.sam.gz' into align
	

    """
	minimap2 -a $contam $fastq > aln.sam; gzip aln.sam

    """

}


process samtools1 {

	memory '16G'
	
	input:
	path samalign from align
	
	output:
	file 'clean1.tst.fastq' into cleanReads1
	
	"""

	gunzip -f $samalign; samtools fastq -n -f 4 aln.sam > clean1.tst.fastq
	
	"""

}


process cutadapt1 {
	
	input:
	path cleanfas from cleanReads1
	
	output:
	file 'R1.fastq' into reads1
	
	"""
	cutadapt --rename='{id}/1' $cleanfas -j 7 -o R1.fastq
	"""

}

//Second  pair

process minimapS32 {

	memory '16G'
	
	input:
	path fastq from sequences12
	path contam from sequences22
	
	output:
	file 'aln.sam.gz' into align2
	

    """
	minimap2 -a $contam $fastq > aln.sam; gzip aln.sam

    """

}


process samtools12 {

	memory '16G'
	
	input:
	path samalign from align2
	
	output:
	file 'clean1.tst.fastq' into cleanReads12
	
	"""

	gunzip -f $samalign ; samtools fastq -n -f 4 aln.sam > clean1.tst.fastq
	
	"""

}


process cutadapt12 {
	
	input:
	path 'cleanfas' from cleanReads12
	
	output:
	file 'R2.fastq' into reads12
	
	"""
	cutadapt --rename='{id}/2' $cleanfas -j 7 -o R2.fastq
	"""

}

process fastqpair {

	input:
	path 'R1fastq' from reads1
	path 'R2fastq' from reads12

	output:
	file 'R1fastq.paired.fq' into pairR1
	file 'R2fastq.paired.fq' into pairR2
	file 'R1fastq.single.fq' into pairR3
	file 'R2fastq.single.fq' into pairR4

	"""
	fastq_pair -t 10000000 $R1fastq $R2fastq
	"""

}


process Trimmomatic {

	input:
	path 'R1pair' from pairR1
	path 'R2pair' from pairR2
	path 'adapt' from adapters


	output:
	file 'R1p.fq' into readTrim1
	file 'R2p.fq' into readTrim2

	"""
	trimmomatic PE -threads 12 $R1pair $R2pair R1p.fq R1up.fq R2p.fq R2up.fq ILLUMINACLIP:$adapt:2:30:10 SLIDINGWINDOW:4:20
	"""

}



process bbnorm {

	memory '16G'
	
        input:
        path seq1 from readTrim1
        path seq2 from readTrim2
        
        output:
        file 'mid.fq' into ReadTrimNorm1

	"""
	bbnorm.sh in=$seq1 in2=$seq2 outlow=low.fq outmid=mid.fq outhigh=high.fq passes=1 lowbindepth=6 highbindepth=120 -Xmx15g
	"""
}


process pairInt {

	input:
	path 'pairInt' from pairInt
	path 'Intpair' from ReadTrimNorm1

	output:
	file 'R1reads.fastq' into R1Tofastq
	file 'R2reads.fastq' into R2Tofastq

	"""
	chmod 744 $pairInt
	./$pairInt < $Intpair R1reads.fastq R2reads.fastq
	"""

}


process fastqpair2 {

	input:
	path R1p from R1Tofastq
	path R2p from R2Tofastq

	output:
	file 'R1reads.fastq.paired.fq' into pairR1T
	file 'R2reads.fastq.paired.fq' into pairR2T
	//For now not even bothering with unpaired

	"""
	fastq_pair -t 10000000 $R1p $R2p
	"""
}

pairR1T.into{P1NormSpades; P1NormTrinity}
pairR2T.into{P2NormSpades; P2NormTrinity}
*/

sequencedataset1= Channel.fromPath(sequences1)
sequencedataset2= Channel.fromPath(sequences12)

sequencedataset1.into{P1NormSpades; P1NormTrinity}
sequencedataset2.into{P2NormSpades; P2NormTrinity}

process SpadeAssemble {
	
	memory '56G'

        input:
        path R1Norm from P1NormSpades
	path R2Norm from P2NormSpades

        //output:
        //file 'hard_filtered_transcripts.fasta' into Spades

        """
        rnaspades.py  --pe1-1 $R1Norm --pe1-2 $R2Norm  -o spades_output
        """
}


/*

process TrinityAssemble {

	memory '96G'

	input:
	path R1pair from P1NormTrinity
	path R2pair from P2NormTrinity

	output:
	file 'Trinity.fasta' into Trinity


	"""
	conda install tbb=2020.2
	Trinity --seqType fq --left $R1pair --right $R2pair --max_memory 54G --output trinity_output
	cp ./trinity_output/Trinity.fasta .
	"""

}

*/

