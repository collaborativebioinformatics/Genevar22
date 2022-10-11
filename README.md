# GeneVar: Effortless SV annotation and interpretation 

![](images/GeneVar2-logo.jpeg)

## WorkFlow

![](genevar-22.png)

### Running RStudio on DNAnexus

https://documentation.dnanexus.com/getting-started/developer-tutorials/web-app-let-tutorials/running-rstudio-server

## Introduction

Next-generation sequencing provides the ability to sequence extended genomic regions or a whole-genome relatively cheaply and rapidly, making it a powerful technique to uncover the genetic architecture of diseases. However, there remain significant challenges, including interpreting and prioritizing the found variants and setting up the appropriate analysis pipeline to cover the necessary spectrum of genetic factors, including expansions, repeats, insertions/deletions (indels), structural variants and point mutations. For those outside the immediate field of genetics – a group that includes researchers, hospital staff, general practitioners, and, increasingly, patients who have paid to have their genome sequenced privately – the interpretation of findings is particularly challenging. Although various tools are available to predict the pathogenicity of a protein-changing variant, they do not always agree, further compounding the problem. Furthermore, with the increasing availability of next-generation sequencing data, non-specialists, including health care professionals and patients, are obtaining their genomic information without a corresponding ability to analyse and interpret it, as the relevance of novel or existing variants in genes is not always apparent. The same is true of structural variant analysis, the interpretation of which also requires care related to sample and platform selection, quality control, statistical analysis, results prioritisation, and replication strategy. Here we present GeneVar2: an open access, gene-centric data browser to support structural variant analysis.



## Goals

[GeneVar](https://github.com/collaborativebioinformatics/GeneVar) is an open access, gene centric data browser for SV analysis. GeneVar takes as input a gene name or ID and produces a report that informs the user of all SVs overlapping the gene and any non-coding regulatory elements affecting expression of the gene. [Clinical SV](https://github.com/collaborativebioinformatics/clinical_SVs) is an open access software that can annotate vcf files with clinically relavant information as well as provide useful visualizations such as disease ontology plots.

GeneVar2 is the integration of these two apps which work together to facilitate reporting of structural variations data. GeneVar2 tool is intended to have a clinical focus, informing the interpretation of SV pertaining to a gene name. In addition, GeneVar2 gives the user the option to upload genotyping data and produces a report, file, and genome browser session that informs the user of all structural variants overlapping the gene, including any non-coding regulatory elements affecting expression of the gene.


## Description

The aim of this project is to merge the functionality of GeneVar and Clinical_SV into one new application, GeneVar2. GeneVar is a gene centric data browser which is great to review a small list of genes individually for the browser allows for in-depth analysis of SVs that overlap a gene of interest. However, many users will typically have variant caller files (VCFs) as output from analysis pipelines.  To better accomodate this use-case, we are combining GeneVar with Clinical_SV which already encompasses the ability to upload and annotat SV vcfs.  In addition, Clinical_SV produces helpful visualizations of Disease Ontology and enrichment pathway analysis based on SV types.

