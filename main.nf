#!/usr/bin/env nextflow


sequences1='s3://transcriptome.seeds.genewiz.rawdata/LO1_R1_001.fastq.gz'
sequences12='s3://transcriptome.seeds.genewiz.rawdata/LO1_R2_001.fastq.gz'
sequences2='s3://transcriptomepipeline/ContaminantsForRemove.fasta'
sequences22='s3://transcriptomepipeline/ContaminantsForRemove.fasta'
adapters='s3://transcriptomepipeline/TruSeq3-PE.fa'
	
process minimapS31 {
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
	
	input:
	path samalign from align
	
	output:
	file 'clean1.tst.fastq' into cleanReads1
	
	"""

	gunzip $samalign; samtools fastq -n -f 4 aln.sam > clean1.tst.fastq
	
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
	
	input:
	path samalign from align2
	
	output:
	file 'clean1.tst.fastq' into cleanReads12
	
	"""

	gunzip $samalign ; samtools fastq -n -f 4 align.sam > clean1.tst.fastq
	
	"""

}


process cutadapt12 {
	
	input:
	val 'cleanfas' from cleanReads12
	
	output:
	file 'R2.fastq' into reads12
	
	"""
	cutadapt --rename='{id}/1' cleanfas.fasta -j 7 -o R2.fastq
	"""

}












