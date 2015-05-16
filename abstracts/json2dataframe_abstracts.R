
library(jsonlite)
library(plyr)
library(dplyr)
library(parallel)

xml2punct <- function(x){
  x <- gsub('<punto>', '.',  x)
  x <- gsub('<coma>', ',',  x)
  x <- gsub('<sep_json>', ':',  x)
  x <- gsub('<dos_puntos>', ':',  x)
  x <- gsub('<punto_coma>', ';',  x)
  x <- gsub('<asterisco>', '*',  x)
  x <- gsub('<comillas_dobles>', '"',  x)
  x <- gsub('<comillas_simples>', "'",  x)
  x <- gsub('<backtick>', '`',  x)
  x <- gsub('<gato>', '#',  x)
  x <- gsub('<abre_corchetes>', '[',  x)
  x <- gsub('<cierra_corchetes>', ']',  x)
  x <- gsub('<abre_parent>', '(',  x)
  x <- gsub('<cierra_parent>', ')',  x)
  x <- gsub('<guion>', '-',  x)
  x <- gsub('<ampersand>', '&',  x)
  x <- gsub('<diagonal>', '/',  x)
  x
}

json2df <- function(y, mc.cores = 4){
  mclapply(y, function(x) as.data.frame(x, stringsAsFactors = F),
                         mc.cores = mc.cores) %>%
    rbind_all %>%
    dplyr::select(Title, Date, Award.Number, Investigator, Sponsor, Fld.Applictn, Abstract) %>%
    apply(2, xml2punct)
}

dict1 <- fromJSON(txt = '../data/big/abstracts_clean_part1.json')
dict2 <- fromJSON(txt = '../data/big/abstracts_clean_part2.json')
dict3 <- fromJSON(txt = '../data/big/abstracts_clean_part3.json')

abstracts1 <- json2df(dict1)
abstracts2 <- json2df(dict2)
abstracts3 <- json2df(dict3)
abstracts <- rbind(
  cbind(file = 1, abstracts1),
  cbind(file = 2, abstracts1),
  cbind(file = 3, abstracts1)
) %>%
  data.frame
names(abstracts) <- c('file','title','date','award_number','investigator','sponsor','field','abstract')

#write.table(abstracts, file = '../data/big/abstracts_clean.psv', sep = '|')
#save(abstracts, file='../data/abstracts_clean.Rdata')









