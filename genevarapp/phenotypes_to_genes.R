# phenotype_to_genes.txt from https://hpo.jax.org/app/download/annotation
#install.packages("tidyverse")
#install.packages("httr")
#install.packages("ICD10gm")

args = commandArgs(TRUE)
if(length(args) == 0){
  ICD_code = "G10"  #Huntington Disease
  out_file = "phenotype_gene_list.csv"
} else {
  ICD_code = args[1]
}
# Packages to install
suppressWarnings(suppressMessages(library(tidyverse, quietly = T)))
suppressWarnings(suppressMessages(library(dplyr, quietly = T)))
suppressWarnings(suppressMessages(library(httr, quietly = T)))
suppressWarnings(suppressMessages(library(ICD10gm, quietly = T)))

# Check if ICD Code or not
if (!is_icd_code(ICD_code)){
  message("ICD Code is Incorrect.")
  # Do Something...
}

# Increase timeout warning since this table is massive
options(timeout=600)
message("Reading in HPO File...")
hpo <- read.table('http://purl.obolibrary.org/obo/hp/hpoa/phenotype_to_genes.txt', header = F, sep = '\t')
message("HPO File Successfully Loaded.")
names(hpo) <- c("HPO-id", "HPO label", "entrez-gene-id", "entrez-gene-symbol", "Additional Info from G-D source", "G-D source", "disease-ID for link")
hpo %>% select(`HPO-id`, `entrez-gene-symbol`, `disease-ID for link`)

#Leveraging ICD API... Using Credentials from Irenaeus Chan chani@wustl.edu
token_endpoint = 'https://icdaccessmanagement.who.int/connect/token'
client_id = 'b357e3f5-213f-4167-909a-c4b756fcdaed_a6040f59-4c30-48dc-8dda-ea526c2c0ffe'
client_secret = '4fs10IlL7853fAAc3cHRBOnLKn0haV8NyV9qchq3If4='
scope = 'icdapi_access'
grant_type = 'client_credentials'

# Get the OAUTH2 token
data_post <- paste0("client_id=", client_id, "&client_secret=", client_secret, "&scope=icdapi_access&grant_type=client_credentials")
message("Obtaining ICD API Token using User Information from Irenaeus Chan - chani@wustl.edu")
res <- httr::content(httr::POST(url= "https://icdaccessmanagement.who.int/connect/token",
                                httr::add_headers('Content-Type'='application/x-www-form-urlencoded'),
                                body = data_post))
# Token Resets in 3600
token = res$access_token
message("Token Obtained: ", token)

# Access ICD API
message("Querying the ICD-10 Database for Disease/Phenotype Associated with ICD-10 Code.")
uri <- "https://id.who.int/icd/release/10/"
input_icdnumber <- "G10"
res <- httr::content(httr::GET(paste0(uri,input_icdnumber), httr::add_headers(c('accept'='application/json', 
                                                                'API-Version'='v2',
                                                                'Accept-Language'='en',
                                                                'Authorization'=paste("Bearer", token)))))
disease_name <- res$title$`@value`
message("Disease Name: ", disease_name)

# We have OMIM Files
message("Reading in OMIM Files...")
mim_titles<-read.table("mimTitles.tsv", sep = "\t", header = TRUE, fill = TRUE, comment.char = '', quote = '')
message("OMIM Files Successfully Loaded.")
# Look for the Disease within our OMIM File
query_hpo <- mim_titles %>% filter(grepl(toupper(disease_name), Preferred_Title)) %>% dplyr::select(MIM_Number) %>% mutate(MIM_Number = paste("OMIM", MIM_Number, sep = ":"))

# Find the OMIM IDs associated with the Disease and query the HPO
hpo_result <- hpo %>% filter(`disease-ID for link` %in% unlist(unname(as.list(query_hpo))))
genes <- hpo_result  %>% dplyr::select(`entrez-gene-id`, `entrez-gene-symbol`) %>% unique()
phenotypes <- hpo_result  %>% dplyr::select(`HPO label`, `HPO-id`) %>% unique()


