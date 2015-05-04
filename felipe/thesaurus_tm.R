
library(jsonlite)
library(plyr)
library(dplyr)
library(parallel)

dict <- fromJSON(txt = '../data/gutenberg_dictionary_clean.json')
head(dict)

# Una entrada a data frame
json2row <- function(record){
  # record debe ser un elemento de la lista, con corchetes dobles o $, d$happy o bien
  # d[['happy']], NO d['happy']
  x <- lapply(record, function(l){
    a <- unlist(l) %>% as.list %>% as.data.frame(stringsAsFactors = F)
    if(is.null(names(l))) a <- NULL
    a
  })
  idx <- sapply(x, function(y) !is.null(y))
  x <- lapply(names(x[idx]), function(y){
    data.frame(id=y, x[[y]], stringsAsFactors = F)
  }) %>% rbind.fill
  if(is.null(x)) x <- data.frame(id = '1', Def = record$Raw)
  x
}
json2row(dict[['showy']]) # Este venía roto, pero ya funciona. Le ponemos el Raw como definición y lo demás NA
json2row(dict[['show']])

# Todas las entradas a data.frame
dict2df <- function(dict, parallel = F, cores = 6){
  # dict es una lista anidada obtenida directamente de fromJSON
  if(length(dict) < 5000 || !parallel){
    x <- lapply(names(dict), function(y){
        u <- json2row(dict[[y]])
        u$Word <- y
        u
      }) %>% rbind_all
  } else {
    x <- mclapply(X = names(dict), mc.cores = 6, FUN = function(y){
      u <- json2row(dict[[y]])
      u$Word <- y
      u
    }) %>% rbind_all
  }
  x
}

#system.time(d <- dict2df(dict[1:20000], parallel = T, cores = 6))
system.time(dict_df <- dict2df(dict, parallel = T, cores = 6))











