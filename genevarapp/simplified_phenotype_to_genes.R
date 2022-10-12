suppressWarnings(suppressMessages(library(tidyverse, quietly = T)))
suppressWarnings(suppressMessages(library(dplyr, quietly = T)))
suppressWarnings(suppressMessages(library(httr, quietly = T)))
suppressWarnings(suppressMessages(library(ICD10gm, quietly = T)))
if (!is_icd_code(input$icd_search)){ message("ICD Code is Incorrect.")}
options(timeout=600)
hpo <- read.table('http://purl.obolibrary.org/obo/hp/hpoa/phenotype_to_genes.txt', header = F, sep = '\t')
names(hpo) <- c("HPO-id", "HPO label", "entrez-gene-id", "entrez-gene-symbol", "Additional Info from G-D source", "G-D source", "disease-ID for link")
hpo %>% select(`HPO-id`, `entrez-gene-symbol`, `disease-ID for link`)
token_endpoint = 'https://icdaccessmanagement.who.int/connect/token'
client_id = 'b357e3f5-213f-4167-909a-c4b756fcdaed_a6040f59-4c30-48dc-8dda-ea526c2c0ffe'
client_secret = '4fs10IlL7853fAAc3cHRBOnLKn0haV8NyV9qchq3If4='
scope = 'icdapi_access'
grant_type = 'client_credentials'
data_post <- paste0("client_id=", client_id, "&client_secret=", client_secret, "&scope=icdapi_access&grant_type=client_credentials")
res <- httr::content(httr::POST(url= "https://icdaccessmanagement.who.int/connect/token",httr::add_headers('Content-Type'='application/x-www-form-urlencoded'),body = data_post))
token = res$access_token
uri <- "https://id.who.int/icd/release/10/"
input_icdnumber <- input$icd_search
res <- httr::content(httr::GET(paste0(uri,input_icdnumber), httr::add_headers(c('accept'='application/json', 'API-Version'='v2','Accept-Language'='en','Authorization'=paste("Bearer", token)))))
disease_name <- res$title$`@value`
mim_titles<-read.table("mimTitles.tsv", sep = "\t", header = TRUE, fill = TRUE, comment.char = '', quote = '')
query_hpo <- mim_titles %>% filter(grepl(toupper(disease_name), Preferred_Title)) %>% dplyr::select(MIM_Number) %>% mutate(MIM_Number = paste("OMIM", MIM_Number, sep = ":"))
hpo_result <- hpo %>% filter(`disease-ID for link` %in% unlist(unname(as.list(query_hpo))))
genes <- hpo_result  %>% dplyr::select(`entrez-gene-id`, `entrez-gene-symbol`) %>% unique()
phenotypes <- hpo_result  %>% dplyr::select(`HPO label`, `HPO-id`) %>% unique()
