> ## GeneVar(2022 update)
<br/>

<!-- <p align="center">
  <img width="400" alt="GeneVar22Logo" src="https://user-images.githubusercontent.com/82537630/195183671-b0479eff-2b73-44b5-aae1-a2682d383919.png">
</p>
 -->
<p align="center">
  <img width="400" alt="PhenoGeneVarSV-logo" src="https://raw.githubusercontent.com/collaborativebioinformatics/Genevar22/main/Images/PhenoGeneVarSV-logo.png">
</p>


![](images/logo.png)


## Contributors (over three hackathons in random order)
Tim Hefferon (Lead),	Rupesh Kesharwani,	Kimberly Walker,	Jędrzej Kubica,	Jean Monlong,	Irenaeus Chan,	Fritz Sedlazeck,	Ben Busby,	Barry Zorman,	Ahmad Al Khleifat,	 Weiyu Zhou, 	 Tingting Zhao,	 Priya Lakra, Jianzhi (Quentin) Yang, Haowei Du,	 Gaojianyong Wang,	 Divya Kalra, 	 David Henke, 	Neda Ghohabi



## Goal

[GeneVar](https://github.com/collaborativebioinformatics/GeneVar) is an open-access, gene centric data browser for structural variants (SVs) analysis.
As clinicians and patients are often comfortable using interactive web-pages, GenVar uses the shiny framework for web tool portability and the processing power of the R data analysis language. The three modes of inquiry for GenVar, namely, by gene ID, VCF file, or phenotype, are intuitive and simple. A doctor or patient can use GenVar to benefit from databases such as dbVar, ClinVar, and OMIM with less time spent looking at raw data in an overwhelming genomic coordinate format.


GeneVar takes a gene name as an input or ID and produces a report that informs the user of all SVs overlapping the gene and any non-coding regulatory elements affecting expression of the gene.

[Clinical SV](https://github.com/collaborativebioinformatics/clinical_SVs) is an open access software that can annotate variant call format (VCF) files with clinically relavant information as well as provide useful visualizations such as disease ontology plots.

[GeneVar2](https://github.com/collaborativebioinformatics/GeneVar2) was the integration of these two apps which work together to facilitate reporting of structural variations data. GeneVar tool is intended to have a clinical focus, informing the interpretation of SV pertaining to the gene name. In addition, GeneVar gives the user the option to upload genotyping data and produces a report, a file, and a genome browser session that informs the user of all SVs overlapping the gene, including any non-coding regulatory elements affecting expression of the gene.

[GeneVar2022](https://github.com/collaborativebioinformatics/Genevar22) is the continuation of the previous iterations of GeneVar. This version has been converted successfully into a DNANexus Applet which can be hosted and used through the DNANexus API or UI. Additional functionality was added to this version of GeneVar by implementing the ability for users to look for SVs based upon disease/phenotype ontology.

## How it works?

There are three ways to interact with GeneVar2022 update):
- First, GeneVar takes a gene name or a gene ID as an input and produces a report that informs the user of all SVs overlapping the gene and any non-coding regulatory elements affecting expression of the gene. 
- Second, users can upload VCF files from their analysis pipelines as an input to GeneVar. GeneVar will output clinically relevant information, as well as provide useful visualizations of disease ontology and enrichment pathway analysis based on SV types. 
- Third, users can submit phenotype or disease ontology terms (ICD-10) and retrieve relevant SVs. GeneVar will convert the ICD-10 code into the specific disease of interest and then look for phenotype matching said disease. Once all information has been gathered, genes associated with the phenotypes presented in the disease will then be summarized and GeneVar will output the associated genes, the gathered phenotypes, and output all SVs overlapping all the genes associated with the disease as well as any non-coding regulator elements that affect the expression of the genes.


## WorkFlow
<!-- <img width="1091" alt="genevar_logo_green" src="https://user-images.githubusercontent.com/82537630/195189567-7220b953-8f89-490d-9dc3-aca30c279656.png"> -->
<p align="center">
  <img width="1100" alt="PhenoGeneVarSV-workflow" src="https://raw.githubusercontent.com/collaborativebioinformatics/Genevar22/main/Images/PhenoGeneVarSV-workflow.png">
</p>



## Background

Next-generation sequencing (NGS) provides the ability to sequence extended genomic regions or whole-genomes cheaply and rapidly, making it a powerful technique to uncover the genetic architecture of diseases. However, significant challenges remain, including interpretation and prioritization of the found variants and setting up the appropriate analysis pipeline to cover the necessary spectrum of genetic factors (such as expansions, repeats, insertions/deletions (indels), structural variants (SVs) and point mutations). For those outside the immediate field of genetics – researchers, hospital staff, general practitioners, and, increasingly, patients who have paid to have their genome sequenced privately – the interpretation of findings is particularly challenging. Although various tools for the prediction of the pathogenicity of a protein-changing variant are available, they do not always agree, further compounding the problem. Furthermore, with the increasing availability of NGS data, non-specialists are obtaining genomic information without a corresponding ability to analyse and interpret it, as the relevance of novel or existing variants is not always apparent. The same is true of SV analysis, the interpretation of which also requires care related to sample and platform selection, quality control, statistical analysis, results prioritisation, and replication strategy.


## Web-App Preview

### GeneVar
<p align="center">
  <img width="1100" alt="Genevar Screen" src="https://raw.githubusercontent.com/collaborativebioinformatics/Genevar22/main/Images/Genevar.png">
</p>

### GeneVar2 / ClinicalSV
<p align="center">
  <img width="1100" alt="Genevar Screen" src="https://raw.githubusercontent.com/collaborativebioinformatics/Genevar22/main/Images/ClinvarSV1.png">
</p>
<p align="center">
  <img width="1100" alt="Genevar Screen" src="https://raw.githubusercontent.com/collaborativebioinformatics/Genevar22/main/Images/ClinvarSV2.png">
</p>

### GeneVar2022
<p align="center">
  <img width="1100" alt="Genevar Screen" src="https://raw.githubusercontent.com/collaborativebioinformatics/Genevar22/main/Images/DPO.png">
</p>

<p align="center">
  <img width="1100" alt="Genevar Screen" src="https://raw.githubusercontent.com/collaborativebioinformatics/Genevar22/main/Images/DPO_SV.png">
</p>

<p align="center">
  <img width="1100" alt="Genevar Screen" src="https://raw.githubusercontent.com/collaborativebioinformatics/Genevar22/main/Images/DPO_onto_plot.png">
</p>


## DNAnexus Implementation

GeneVar2 has been converted into a DNANexus Applet as per instructions provided here: https://documentation.dnanexus.com/getting-started/developer-tutorials/web-app-let-tutorials/running-rstudio-shiny-server-and-apps

To run the GeneVar2 Applet, simply Log into DNANexus, select GeneVar2 from the list of analyses and start the analysis. This GeneVar2 applet is self-contained and all required environment settings have been converted into a Docker for ease-of-use. The applet will take a few minutes to start depending on the availability of the selected Instance Type. 

Once the GeneVar2 Applet has started to run. Simply click the provided Worker URL to launch the RShiny Web Application hosted on DNANexus and use GeneVar2 as described previously.

## References

1. https://github.com/collaborativebioinformatics/GeneVar
2. https://github.com/collaborativebioinformatics/clinical_SVs
3. https://github.com/collaborativebioinformatics/GeneVar2

Papers associated with the development of GeneVar:

McCartney AM, Mahmoud M, Jochum M et al. An international virtual hackathon to build tools for the analysis of structural variants within species ranging from coronaviruses to vertebrates F1000Research 2021, 10:246 (https://doi.org/10.12688/f1000research.51477.2) https://f1000research.com/articles/10-246

Walker K, Kalra D, Lowdon R et al. The third international hackathon for applying insights into large-scale genomic composition to use cases in a wide range of organisms. F1000Research 2022, 11:530 (https://doi.org/10.12688/f1000research.110194.1) https://f1000research.com/articles/11-530


## Future Directions 
- [ ] Permanently Hosted Application
  - [ ] Server
  - [ ] Command Line Tool
  
## Hackathon Acknowledgments

<p align="center">
  <img width="1100" alt="Thank You" src="https://raw.githubusercontent.com/collaborativebioinformatics/Genevar22/main/Images/PhenoGeneVarSV-thankyou.png">
</p>

