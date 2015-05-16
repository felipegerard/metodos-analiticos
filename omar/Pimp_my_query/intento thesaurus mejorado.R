
library(Matrix)
library(dplyr)
library(tm)
library(ggplot2)
library(wordcloud)


################################################  lectura de la informacion ###########################################

#load('output/gutenberg_data_frame.Rdata')
View(dict_df)


###################################  limpieza de la informacion y creacion del corpus ##################################

d <- dict_df %>%
  filter(grepl('^[a-z]', Word), id != 'Metadata', Def != '')
dim(d)
corpus.frases <- Corpus(VectorSource(d$Def))
corpus.frases
corp.1 <- tm_map(corpus.frases,  function(x){
  gsub('--|[«»\\\',;:".!¡¿?\\(\\)\\[\\]&0-9\\*#/]|<br>','',x) # Checar escapes de &*[]
})
corp.2 <- tm_map(corp.1, function(x) stripWhitespace(x) %>% tolower %>% PlainTextDocument)



############################  Creacion de la matriz terminos documentos y los pesos por ntc ############################

tdm.1 <- TermDocumentMatrix(corp.2, control=list(wordLengths=c(1, Inf)))
tdm.2 <- weightSMART(tdm.1, spec = 'ntc')
colnames(tdm.2) <- paste(d$Word, d$id, sep='_')


#####################################  revisamos la normalizacion de los pesos #########################################

head(sort(vec.1 <- as.matrix(tdm.2[,'action_1']),dec=T))


########################################################  Query #######################################################

query <- 'i would like to go to the green park and spend a great time with my friends'
query <- 'wine'

query <- 'car'

if(sapply(gregexpr("\\W+", query), length) + 1 == 2) {
  #si la longitud del query es de 1 entonces, buscamos y limpiamos su definicion
  
  if(is.na(d[which(d$Word %in% query)[1],]$Def)){
    aux <- tm_map(Corpus(VectorSource(query)),removeWords,stopwords("english"))
  }else{
    definicion <- paste(query,d[which(d$Word %in% query)[1],]$Def)
    definicion <- gsub('--|[],;:.[]|<br>|[()«»"#*`¿?¡!/&%$=]','',definicion)
    definicion <- tm_map(Corpus(VectorSource(definicion)), function(x) stripWhitespace(x) %>% tolower %>% PlainTextDocument)
    definicion <- tm_map(definicion,removeWords,stopwords("english"))
    aux <- definicion
    
  }
}else{
  aux <- tm_map(Corpus(VectorSource(query)),removeWords,stopwords("english"))
}



################################################ Multiplicacion query * tdm ############################################

mat.1 <- sparseMatrix(i=tdm.2$i, j=tdm.2$j, x = tdm.2$v)
dictionary <- tdm.2$dimnames$Terms
query.vec.1 <- TermDocumentMatrix(aux, 
                                  control = list(dictionary = dictionary,
                                                 wordLengths=c(1, Inf))) 
query.vec.norm <- as.matrix(query.vec.1)/sqrt(sum(query.vec.1^2))
aa <- t(mat.1)%*%query.vec.norm


###################################################  top 15 palabras ##################################################
idx_top <- order(aa, decreasing=T)
out <- d[idx_top,] %>%
  select(Word, id, Def) %>%
  cbind(score = sort(aa,decreasing = T)) %>%
  filter(score > 0)
res <- out %>% head(15)
res$Def <- gsub('<br>','',res$Def)
View(res)


##############################################  histograma de discriminacion ##########################################

m <- data.frame(min=min(res$score))
# Estadísticas. Son sobresalientes las palabras que mostramos?
ggplot() +
  geom_bar(data=out, mapping=aes(x=score)) +
  geom_vline(data=res, aes(xintercept=min(score)), color='red')



############################################### contribucion de las palabras #########################################
best <- function(nmatch = 3, nterm = 5){
  v.q <- query.vec.norm
  outlist <- list()
  for(i in 1:nmatch){
    #colnames(tdm.2)[idx_top[i]]
    #idx_top[nmatch]
    v.j <- mat.1[,idx_top[i]]
    v <- v.j*v.q
    #length(v)
    top_contrib <- order(v, decreasing = T)
    outlist[[i]] <- data.frame(term=dictionary[top_contrib[1:nterm]], # tdm.2$dimnames$Terms[top_contrib[1]]
                               score_contrib=v[top_contrib[1:nterm]], stringsAsFactors=F) %>%
      filter(score_contrib > 0) %>%
      data.frame(rank = i, match = colnames(tdm.2)[idx_top[i]], total_score = sum(v), stringsAsFactors = F)
  }
  rbind_all(outlist)[c(3,4,5,1,2)] %>%
    group_by(term) %>%
    summarise(contrib=sum(score_contrib)) %>%
    arrange(desc(contrib))
}

best <- best(nmatch = 15, nterm = nrow(unique(as.data.frame(strsplit(as.character(aux[[1]])," ")[[1]]))))


########################################################  wordcloud ##################################################

wordcloud(best$term,best$contrib,
          scale=c(5,.7),
          min.freq=0.1,
          ordered.colors=T,
          colors=colorRampPalette(brewer.pal(9,"Set1"))(nrow(best)))

