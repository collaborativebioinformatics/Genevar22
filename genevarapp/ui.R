library(shiny)
library(DT)
library(shinydashboard)
library(dplyr)

message('ui.R load genes')
## genes.df = read.table('gencode.tsv.gz', as.is=TRUE, header=TRUE)
## genes.df = genes.df %>% filter(chr %in% 1:2)

## ## list all genes
## genes = unique(c(genes.df$gene_id, genes.df$gene_name, genes.df$transcript_id))
## ## genes = unique(c('ENST00000400454.6', genes))

## merge general variant info
svtypes = c('DEL', 'DUP', 'INV', 'INS')
svsize.max = 1e9

ui <- dashboardPage(
  dashboardHeader(title='GeneVar'),
  dashboardSidebar(
    textInput('gene_search', 'Gene', ''),
    textOutput('genevar_example'),
    # div(p('   Search by gene name, gene id (ENSG...), or transcript ID (ENST...)'),
    #     p('   Examples:'),
    #     p('   DSCAM'),
    #     p('   ENSG00000171587.15'),
    #     p('   ENST00000400454.6')),
    textInput('icd_search', 'ICD-10 Code', 'G10'),
    actionButton("submit_icd", "Search", icon = icon("search"), class = "btn btn-primary"),
    checkboxGroupInput('svtypes', "SV type", svtypes, svtypes),
    numericInput('size.min', 'Minimum SV size (bp)', 0, 0),
    numericInput('size.max', 'Maximum SV size (bp)', svsize.max, svsize.max),
    ## clinical sv
    fileInput(
      "file",
      label = "Upload the VCF file (.vcf)",
      accept = c(".vcf","text/csv","text/comma-separated-values, text/plain"),
      placeholder = " No file selected",
      multiple = TRUE,
      width = "100%"
    ),
      numericInput("pvalue",
                        "p-value",
                        value = 0.1),
    textInput('svtype.for.annotation', 'SV type for gene annotation (e.g., DUP)', ''),
    textInput('chr.for.annotation', 'SV chromosome for gene annotation (e.g., chr12)', ''),
    actionButton(
      "submit",
      "Anotate",
      icon = icon("search"),
      width = "70%",
      class = "btn btn-primary"
      # )
    ),
   #textOutput('fileselected'),
    #splitLayout(
      downloadButton('downloadvcf', 'Download annotated VCF'),
      downloadButton('downloadcsv', 'Download annotated CSV'),
      # downloadButton('downloadPlot', 'Download Plots'),
      downloadButton('downloadZip', 'Download Zip')
   # )
    ##
  ),

  dashboardBody(
    tabsetPanel(type = "tabs",
                tabPanel("Genevar",
                htmlOutput('title'),
                fluidRow(
                  ## A static infoBox
                  infoBoxOutput("sv_box"),
                  infoBoxOutput("path_sv_box"),
                  infoBoxOutput("path_snv_box")
                ),
                shiny::htmlOutput('omim_url', class='btn btn-default action-button shiny-bound-input'),
                shiny::htmlOutput('gtex_url', class='btn btn-default action-button shiny-bound-input'),
                shiny::htmlOutput('gnomad_url', class='btn btn-default action-button shiny-bound-input'),
                hr(),
                dataTableOutput('vars_table'),
                hr(),
                h2('Allele frequency distribution'),
                plotOutput('af_plot')),
                tabPanel("ClinicalSV",
                         dataTableOutput('clinicalsv_table'),
                         hr(),
                         plotOutput('clinicalsv_plot')
                         ),
                tabPanel("Disease/Phenotype Ontology",
                         htmlOutput('title_2'),
                         fluidRow(
                           splitLayout(cellWidths = c("50%", "50%"), dataTableOutput("gene_list"), dataTableOutput("phenotype_list"))
                           ),
                         hr(),
                         dataTableOutput("comb_vars_table"),
                         hr(),
                         plotOutput('dpo_plot')
                         )
    )

     # bsModal("modalExample", "Your plot", "submit", size = "large",tableOutput("clinicalsvtable"),downloadButton('downloadcsv', 'Download'))
  )



  # dashboardBody(
  #   uiOutput("clinicalsvtable")
  # )
)

