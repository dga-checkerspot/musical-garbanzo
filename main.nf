#!/usr/bin/env nextflow


sequences1='s3://transcriptome.seeds.genewiz.rawdata/LO1_R1_001.fastq.gz'
sequences12='s3://transcriptome.seeds.genewiz.rawdata/LO1_R2_001.fastq.gz'
sequences2='s3://transcriptomepipeline/ContaminantsForRemove.fasta'
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
