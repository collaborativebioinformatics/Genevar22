library(dplyr)
library(shiny)
library(DT)
library(ggplot2)
library(shinydashboard)
library(Rsamtools)
library(GenomicRanges)
library(stringdist)
library(reticulate)
library(cowplot)
library(purrr)
library(ICD10gm)
library(ontologyIndex)
library(ontologyPlot)
message('local files')
message(list.files())

message('load genes')
genes.df = read.table('gencode.tsv.gz', as.is=TRUE, header=TRUE)
pli.df = read.table('pli.gene.tsv.gz', as.is=TRUE, header=TRUE)

## list all genes
genes = unique(c(genes.df$gene_id, genes.df$gene_name, genes.df$transcript_id))
## genes = unique(c('ENST00000400454.6', genes))

if (file.info("dbvar38.ann.tsv.gz")$size < 150000000){
  message("git lfs clone did not download dbvar38.ann.tsv.gz properly.")
} else {
  vars.tbx <- TabixFile('dbvar38.ann.tsv.gz', index='dbvar38.ann.tsv.gz.tbi') 
}

getVars <- function(chr, start, end){
  param <- GRanges(chr, IRanges(start, end))
  res <- scanTabix(vars.tbx, param=param)
  vars.df = read.csv(textConnection(res[[1]]), sep="\t", header=FALSE)
  colnames(vars.df) = c('chr', 'start', 'end', 'variant_id', 'type', 'af', 'clinical_sv', 'clinical_snv')
  vars.df %>% mutate(size=end-start)
}
## vars.df = getVars(1, 0, 1e5)

overlapVarsGenes <- function(vars.df, genes.df){
  vars.gr = makeGRangesFromDataFrame(vars.df)
  genes.gr = makeGRangesFromDataFrame(genes.df)
  var.gene.df = findOverlaps(vars.gr, genes.gr) %>% as.data.frame %>%
    mutate(variant_id=vars.df$variant_id[queryHits],
           gene_id=genes.df$gene_id[subjectHits],
           gene_name=genes.df$gene_name[subjectHits],
           transcript_id=genes.df$transcript_id[subjectHits],
           exon_number=genes.df$exon_number[subjectHits],
           type=genes.df$type[subjectHits]) %>%
    select(-queryHits, -subjectHits) %>% unique
  var.gene.df = var.gene.df %>%
    group_by(variant_id, gene_id, gene_name, transcript_id, type) %>%
    summarize(exon_number=paste(sort(unique(exon_number)), collapse=';'))
  gene.var = var.gene.df %>%
    group_by(variant_id, type) %>%
    summarize(exon_number=ifelse(any(exon_number!=''),
                                 paste0(sort(unique(exon_number)), collapse='|'),
                                 '')) %>%
    mutate(elt_type=ifelse(exon_number!='', paste0(type, '(', exon_number, ')'), type)) %>%
    select(-type)
  merge(gene.var, vars.df) %>%
    group_by(chr, start, end, variant_id, size, type, af, clinical_sv, clinical_snv) %>%
    summarize(gene_impact=paste(sort(unique(elt_type)), collapse=';')) %>% ungroup
}

svtypes = c('DEL', 'DUP', 'INV', 'INS')
svsize.max = 1e9

## function to add links to the variant table
dtify <- function(df){
  if(nrow(df) == 0) return(df)
  df = df %>% mutate(type=factor(type), coord=paste0(chr, ':', start, '-', end)) %>%
    dplyr::select(-chr, -start, -end) %>%
    dplyr::select(variant_id, coord, type, size, af, everything()) %>%
    mutate(clinical_snv=as.character(clinical_snv),
           variant_id=paste0('<a href="https://www.ncbi.nlm.nih.gov/dbvar/variants/',
                             variant_id, '" target="_blank">', variant_id, '</a>'))
}

## function to add links to the Gene Table
dtify_gene <- function(df){
  if(nrow(df) == 0) return()
  df = df %>% mutate(OMIM=paste0('<a href="https://www.genenames.org/tools/search/#!/genes?query=', `entrez-gene-symbol`, '" target="_blank">OMIM:', `entrez-gene-symbol`, '</a>'),
                     GTEx=paste0('<a href="https://gtexportal.org/home/gene/', `entrez-gene-symbol`, '" target="_blank">GTEx:', `entrez-gene-symbol`, '</a>'),
                     gnomAD=paste0('<a href="https://gnomad.broadinstitute.org/gene/', `entrez-gene-symbol`, '" target="_blank">gnomAD:', `entrez-gene-symbol`, '</a>'))
  return(df)
}

## function to add links to the Phenotype Table
dtify_phenotypes <- function(df){
  if(nrow(df) == 0) return(df)
  df = df %>% mutate(`HPO-ID URL`=paste0('<a href="https://hpo.jax.org/app/browse/term/', `HPO-id`, '" target="_blank">HPO:', `HPO-id`, '</a>'))
  return(df)
}

## server side of the app
server <- function(input, output, session) {
  ## reactive conductor to extract gene name for a search
  geneName <- reactive({
    message('Gene searched: ', input$gene_search)
    gene_name = input$gene_search
    ## if no genes selected, select first gene name
    if(gene_name == ''){
      gene_name = 'PCSK9'
    }
    if(all(gene_name != genes.df$gene_name)){
      gene.var = genes.df %>%
        filter(gene_id==input$gene_search | gene_name==input$gene_search | transcript_id==input$gene_search)
      gene_name = head(gene.var$gene_name, 1)
    }
    if(length(gene_name) == 0) gene_name = ''
    return(gene_name)
  })
  ## reactive conductor to apply the filtering only once for all elements that need it
  selVars <- reactive({
    genen = geneName()
    message('Gene: ', genen)
    ## find gene
    gene.sel = genes.df %>% filter(gene_id==genen | gene_name==genen | transcript_id==genen)
    if(nrow(gene.sel)==0){
      message('no gene, return')
      return(tibble())
    }
    ## get variants for the gene's region
    vars.df = getVars(gene.sel$chr[1], min(gene.sel$start), max(gene.sel$end))
    message(nrow(vars.df), ' variants')
    ## overlap with genes
    vars.sel = overlapVarsGenes(vars.df, gene.sel)
    ## filter variants
    vars.sel = vars.sel %>% filter(type %in% input$svtypes,
                                   size >= input$size.min,
                                   size <= input$size.max) %>%
      arrange(desc(clinical_sv))
  })
  ## Text
  output$title = renderText({
    genen = geneName()
    if(genen == ''){
      ## agrep(input$gene_search, genes, value=TRUE)
      hints = genes[head(order(stringdist(input$gene_search, genes)))]
      genen = paste('Gene', input$gene_search, 'not found. Close matches:', paste(hints, collapse=' '))
    }
    paste0('<h1>', genen, '</h1>')
  })
  output$omim_url = renderText({
    return(as.character(a('OMIM', href=paste0('https://www.genenames.org/tools/search/#!/genes?query=', geneName()), target='_blank')))
  })
  output$gtex_url = renderText({
    return(as.character(a('GTEx', href=paste0('https://gtexportal.org/home/gene/', geneName()), target='_blank')))
  })
  output$gnomad_url = renderText({
    return(as.character(a('gnomAD', href=paste0('https://gnomad.broadinstitute.org/gene/', geneName()), target='_blank')))
  })
  output$genevar_example = renderText({
    as.character(  '  Search by gene name, gene id (ENSG...), or transcript ID (ENST...):
                 Examples:
                 DSCAM
                 ENSG00000171587.15
                 ENST00000400454.6
               ')
  })


  ## boxes
  output$sv_box <- renderInfoBox({
    infoBox("SVs", nrow(selVars()), icon=icon("dna"), color="blue")
  })
  output$path_sv_box <- renderInfoBox({
    infoBox("Clinical SVs", sum(grepl('Pathogenic', selVars()$clinical_sv)),
            icon=icon("stethoscope"), color="red")
  })
  output$path_snv_box <- renderInfoBox({
    infoBox("Overlap Clinical SNVs", sum(grepl('Pathogenic', selVars()$clinical_snv)),
            icon=icon("stethoscope"), color="red")
  })
  ## dynamic tables
  output$vars_table <- renderDataTable(
    datatable(dtify(selVars()),
              filter='top',
              rownames=FALSE,
              escape=FALSE,
              options=list(pageLength=15, searching=TRUE)))
  ## Graph
  output$af_plot = renderPlot({
    df = selVars()
    if(nrow(df)==0) return()
    ggplot(selVars(), aes(x=af)) + geom_histogram() + theme_bw() + xlab('allele frequency') + xlim(-.1,1.1)
  })

  ## clinical sv ----------------------
  observe({
    shinyjs::toggleState("submit", !is.null(input$file) && input$file != "")
  })



  # dataset <- reactive({
  #   in.vcf =  paste0(input$file)
  #   annot.rdata = 'annotation_data.RData'
  #   out.vcf = 'clinical-sv-annotated.vcf'
  #   out.csv = 'clinical-sv-table.csv'
  #   system(paste("Rscript annotate_vcf.R",in.vcf,annot.rdata,out.vcf,out.csv,sep = " "))
  #
  #   file.create("input_location.txt")
  #   writeLines(input$file$datapath, "input_location.txt")
  #   source_python('retrieve.py')
  #   ## gene annotation from csv
  #
  #   system(paste("Rscript GeneAnnotationFromCSV.R clinical-sv-table.csv",input$pvalue,input$svtype.for.annotation,input$chr.for.annotation,sep=" "))
  #
  # })

  # output$newvcf <- renderDataTable({
  #   dataset()
  # })
  #vcf.o <- readSVvcf("clinical-sv-annotated.vcf", out.fmt='vcf', keep.ids=TRUE)
  # vcf.o <- readVcf("clinical-sv-annotated.vcf")
  # vr.vcf <- makeVRangesFromGRanges(vcf.o)

  clinicalsv <- eventReactive(input$submit, {
    updateTabsetPanel(session = session, inputId = "tabs", selected = "Annotated")
    withProgress(message = 'In progress', value = 0, {
      in.vcf = paste0(input$file$datapath)
      annot.rdata = 'annotation_data.RData'
      out.vcf = 'clinical-sv-annotated.vcf'
      out.csv = 'clinical-sv-table.csv'
      incProgress(0.05, detail = "5% complete")
      system(paste("Rscript annotate_vcf.R",in.vcf,annot.rdata,out.vcf,out.csv,sep = " "))
      incProgress(0.5, detail = "50% complete")
      file.create("input_location.txt")
      message("File Datapath:", input$file$datapath)
      message("File: ", input$file)
      writeLines(input$file$datapath, "input_location.txt")
      #source_python('retrieve.py')
      incProgress(0.75, detail = "75% complete")
      ## gene annotation from csv

      system(paste("Rscript GeneAnnotationFromCSV.R clinical-sv-table.csv",input$pvalue,input$svtype.for.annotation,input$chr.for.annotation,sep=" "))

#
#       output$clinicalsv_plot <- renderPlot({
#         png.names <- substr(list.files(pattern = "png$", full.names=TRUE),3,100)
#         png.names <- png.names[which(png.names!="output.png")]
#         rl = lapply(png.names, png::readPNG)
#         gl = lapply(rl, grid::rasterGrob)
#         gridExtra::grid.arrange(grobs=gl,ncol=1)
#       }, width = 1000)
#       output$clinicalsv_plot_1 <- renderPlot({
#       base64enc::dataURI(file=png.names[[1]], mime="image/png")
# })

      output$clinicalsv_plot <- renderPlot({
        rds.names <- substr(list.files(pattern = "rds$", full.names=TRUE),3,100)
        rl = lapply(rds.names, readRDS)
        plot_grid(plotlist = rl,ncol = 1)
        # gl = lapply(rl, ggplotGrob)
        # gridExtra::grid.arrange(grobs=gl)
      },height = 1500)
      incProgress(1, detail = "Ready to download")

    })
    read.csv("clinical-sv-table.csv")
    # output$clinicalsvtable <- renderUI({
    #   # this UI will show a plot only if "Using JS" is clicked
    #   if (input$submit > 0)
    #     # the margin-top attribute is just to put the plot lower in the page
    #     div(style = "margin-top:800px", renderDataTable(
    #       read.csv("clinical-sv-table.csv")
    #     ))
    # })
  })
  
  
  output$clinicalsv_table <- renderDataTable({
    datatable(clinicalsv(),
              options = list(scrollX=TRUE, scrollCollapse=TRUE))
  })
  
  # ---------------------------------
  # ICD-10 Disease/Phenotype to Genes
  # ---------------------------------
  observe({
    message(input$submit_icd)
    shinyjs::toggleState("submit_icd", !is.null(input$icd_search) && input$icd_search != "")
  })
  
  icd_to_genes <- eventReactive(input$submit_icd, {
    message("Entering ICD to Genes")
    if (!is_icd_code(input$icd_search)){ 
      message("ICD Code is Incorrect.")
      genes <- data.frame()
      phenotypes <- data.frame()
      disease_name <- "This ICD-10 Code Does Not Exist."
    } else {
      updateTabsetPanel(session = session, inputId = "tabs", selected = "Disease/Phenotype Ontology")
      l <- readLines("simplified_phenotype_to_genes.R")
      n <- length(l)
      withProgress(message = 'Searching Databases...', value = 0, {
        for (i in 1:n) {
          eval(parse(text=l[i]))
          incProgress(1/n, detail = paste(floor(i/n*100), "% Completed." ))
        }
      })
      message("Genes: ", genes)
      message("Phenotypes: ", phenotypes)
      message("Finished Searching Disease/Phenotype")
      genes <- dtify_gene(genes)
      phenotypes <- dtify_phenotypes(phenotypes) 
    }
    return(list(genes, phenotypes, disease_name))
  })
  
  output$title_2 = renderText({
    paste0('<h1>', input$icd_search, ": ", icd_to_genes()[[3]], '</h1>')
  })
  
  output$gene_list <- renderDataTable(
    datatable(icd_to_genes()[[1]], rownames = FALSE, escape = FALSE, options = list(pageLength=15))
  )
  
  output$phenotype_list <- renderDataTable(
    datatable(icd_to_genes()[[2]], rownames = FALSE, escape = FALSE, options = list(pageLength=15, searching = TRUE))
  )
  
  selMultiVars <- reactive({
    genen = icd_to_genes()[[1]]$`entrez-gene-symbol`
    vars.sel.multi <- data.frame()
    withProgress(message = 'Compiling all information...', value = 0, {
      for (i in 1:length(genen)){
        message(genen[i])
        ## find gene
        gene.sel = genes.df %>% filter(gene_id==genen[i] | gene_name==genen[i] | transcript_id==genen[i])
        if(nrow(gene.sel)==0){
          message('no gene, return')
        }
        ## get variants for the gene's region
        vars.df = getVars(gene.sel$chr[1], min(gene.sel$start), max(gene.sel$end))
        message(nrow(vars.df), ' variants for gene: ', genen[i])
        ## overlap with genes
        vars.sel = overlapVarsGenes(vars.df, gene.sel)
        vars.sel <- vars.sel %>% mutate(Entrez_Gene_Symbol = genen[i]) %>%
          select(chr, start, end, Entrez_Gene_Symbol, variant_id, size, type, af, clinical_sv, clinical_snv, gene_impact)
        ## filter variants
        vars.sel.multi <- rbind(vars.sel.multi, vars.sel %>% filter(type %in% input$svtypes,
                                       size >= input$size.min,
                                       size <= input$size.max))
        incProgress(1/i, detail = paste(floor(i/length(genen)*100), "% Completed." ))
      }
    })
    vars.sel.multi <- vars.sel.multi %>% arrange(desc(clinical_sv))
    return(dtify(vars.sel.multi))
  })
  
  output$comb_vars_table <- renderDataTable(
    datatable(selMultiVars(),
              filter='top',
              rownames=FALSE,
              escape=FALSE,
              options=list(pageLength=15, searching=TRUE)))
  
  output$dpo_plot <- renderPlot({
    data(hpo)
    onto_plot(hpo, icd_to_genes()[[2]]$`HPO-id`)
  },height = 1500)


  # eventReactive(input$submit, {
  #   in.vcf = input$file
  #   annot.rdata = 'annotation_data.RData'
  #   out.vcf = 'clinical-sv-annotated.vcf'
  #   out.csv = 'clinical-sv-table.csv'
  #   system(paste("Rscript annotate_vcf.R",in.vcf,annot.rdata,out.vcf,out.csv,sep = " "))
  #
  #   file.create("input_location.txt")
  #   writeLines(input$file$datapath, "input_location.txt")
  #   source_python('retrieve.py')
  #   ## gene annotation from csv
  #
  #   system(paste("Rscript GeneAnnotationFromCSV.R clinical-sv-table.csv",input$pvalue,input$svtype.for.annotation,input$chr.for.annotation,sep=" "))
  #
  # })

  output$downloadvcf <- downloadHandler(
    filename = function() {
      paste0(input$file, '_annotated', '.vcf')
    },
    content = function(con) {
      file.copy("clinical-sv-annotated.vcf", con, overwrite=TRUE)
      #writeVcf(vcf.o, con)
    }
  )

  output$downloadcsv <- downloadHandler(
    filename = function() {
      paste0(input$file, '_annotated', '.csv')
    },
    content = function(con) {
      file.copy("clinical-sv-table.csv", con, overwrite=TRUE)
      # write.csv(dataset(),con)
    }
  )

  # output$downloadPlot <- downloadHandler(
  #   filename = function() { paste0(input$file, '.png')},
  #   content = function(con) {
  #     file.copy("output.png", con, overwrite=TRUE)
  #   }
  # )
  output$downloadZip <- downloadHandler(
    filename = function(){
      paste0(input$file,"_annotated.zip")
    },
    content = function(con){
      # tmpdir <- tempdir()
      #setwd(tempdir())
      filesToSave <- c(
        "clinical-sv-annotated.vcf",
        "clinical-sv-table.csv",
        "output.png",
        list.files(pattern = paste0("^[",input$chr.for.annotation,"_",input$svtype.for.annotation,"]png$"), full.names=TRUE)
      ) #List to hold paths to your files in shiny
      #output$fileselected <- renderText({
      #  paste0('You have selected: ', list.files(pattern = "^c" ))
      #})
      #Put all file paths inside filesToSave...
      #file.copy("li.zip", con, overwrite=TRUE)
      zip(zipfile=con, files = filesToSave)
    },
    contentType = "application/zip"
  )


}
