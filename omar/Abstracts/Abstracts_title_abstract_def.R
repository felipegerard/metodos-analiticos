library(Matrix)
library(dplyr)
library(tm)
library(slam)
library(Rstem)
library(ggplot2)
library(wordcloud)

#install.packages("Rstem", repos = "http://www.omegahat.org/R", type="source")


################################################  lectura de la informacion ###########################################


setwd("~/Dropbox/ITAM_Master/Metodos_Analiticos/Final_MA/omar/Abstracts")

load('abstracts_clean.Rdata')
abstracts2 <- as.data.frame(abstracts2)




########################################################  Query #######################################################

query <- 'Polarity Transistion Studies in the Waianae Volcano: From the Gilbert-Gauss to<br> the Upper Kaena Reversals'
query <- 'Markov Chain Monte Carlo'
query  <- 'MCMC'

#limpieza del query
query.limp <- Corpus(VectorSource(query))
query.limp <- tm_map(query.limp,function(x){
  q1 <- gsub('[-]|<br>',' ',x)
  gsub('[()]|[.,;:`"*#&/><]|[\\\']|[]\\[]','',q1)
})
query.limp <- tm_map(query.limp,removeWords,stopwords("english"))
query.limp <- tm_map(query.limp, function(x) stripWhitespace(x) %>% tolower)
query.limp <- tm_map(query.limp,function(x){
  z <- strsplit(x, " +")[[1]]
  z.stem <- wordStem(z, language="english")
  PlainTextDocument(paste(z.stem, collapse=" "))
})


###################################  limpieza de la informacion y creacion del corpus (datos) ##################################

# filtramos cosas feas en abstract y title
d <- abstracts2 %>%
  filter(grepl('Presidential Awardee',Title)=='FALSE') %>% #815
  filter(grepl('Not Available',Abstract)=='FALSE') %>% #1267
  filter(Title != '') %>% #8
  filter(Abstract != '' ) %>% #2180
  filter(grepl('-----------------------------------------------------------------------',Abstract)=='FALSE') %>%
  mutate(id=row_number()) %>%
  select(id,Title,Abstract,Fld.Applictn,Date,Sponsor,Investigator,Award.Number)


################################################  Análisis por Título (title) #####################################


# creamos el corpus y limpiamos caracteres especiales del titulo
corpus.title <- Corpus(VectorSource(d$Title))


corp.1 <- tm_map(corpus.title,function(x){
  c1 <- gsub('[-]|<br>',' ',x)
  gsub('[()]|[.,;:`"*#&/><]|[\\\']|[]\\[]','',c1)
})
corp.1 <- tm_map(corp.1,removeWords,stopwords("english"))
corp.1 <- tm_map(corp.1, function(x) stripWhitespace(x) %>% tolower)
corp.1 <- tm_map(corp.1,function(x){
  z <- strsplit(x, " +")[[1]]
  z.stem <- wordStem(z, language="english")
  PlainTextDocument(paste(z.stem, collapse=" "))
})


###################  Creacion de la matriz terminos documentos y los pesos por ntc (title)  ############################

#creamos la matriz terminos documentos
tdm.title <- TermDocumentMatrix(corp.1, control=list(wordLengths=c(2, Inf)))
colnames(tdm.title) <- seq(1,tdm.title$ncol)

tdm.title <- weightSMART(tdm.title, spec = 'ntc')

#####################################  revisamos la normalizacion de los pesos (title) #########################################

head(sort(as.matrix(tdm.title[,500]),dec=T))

################################################ Multiplicacion query * tdm (title) ############################################

mat.title <- sparseMatrix(i=tdm.title$i, j=tdm.title$j, x = tdm.title$v)
dictionary_title <- tdm.title$dimnames$Terms
query.vec.title <- TermDocumentMatrix(query.limp, 
                                  control = list(dictionary = dictionary_title,
                                                 wordLengths=c(1, Inf))) 

query.vec.title <- as.matrix(query.vec.title)/sqrt(sum(query.vec.title^2)) #normalizar con ntc el query


vec_title <- t(mat.title)%*%query.vec.title

###################################################  top 15 docs (title) ##################################################
idx_top <- order(vec_title, decreasing=T)
out_title <- d[idx_top,] %>%
  select(id,Title, Date, Sponsor, Abstract) %>%
  cbind(score_title = sort(vec_title,decreasing = T)) 

res_title <- out_title %>% head(15)
res_title$Abstract <- gsub('<br>','',res_title$Abstract)
res_title$Title <- gsub('<br>','',res_title$Title)
res_title$Sponsor <- gsub('<br>','',res_title$Sponsor)


#############################################  corups abstracts (abstracts) ##################################################

daux <- d %>%
  mutate(a=gsub('[-]|<br>',' ',Abstract),
         a=gsub('[()]|[.,;:`"*#&/><]|[\\\']|[]\\[]','',a),
         a=gsub(' +',' ',a),
         a=gsub('^ | $','',a)) %>%
  filter(a != ' ' , a != '', !grepl('(^([^ ] )+[^ ]$)|(^NA$)|(R o o t)', a))
aux <- daux$a

# creamos el corpus y limpiamos caracteres especiales
corpus.abstract <- Corpus(VectorSource(aux))


corp.2 <- tm_map(corpus.abstract,removeWords,stopwords("english"))
corp.2 <- tm_map(corp.2, function(x) stripWhitespace(tolower(x)))
corp.2 <- tm_map(corp.2,function(x){
  z <- strsplit(x, " +")[[1]]
  z.stem <- wordStem(z, language="english")
  PlainTextDocument(paste(z.stem, collapse=" "))
})

#################  Creacion de la matriz terminos documentos y los pesos por ntc (abstracts) ############################

#creamos la matriz terminos documentos
tdm.abst <- TermDocumentMatrix(corp.2, control=list(wordLengths=c(3, Inf)))
colnames(tdm.abst) <- seq(1,tdm.abst$ncol)

tdm.abst <- weightSMART(tdm.abst, spec = 'ntc')

##################################  revisamos la normalizacion de los pesos (abstracts) #########################################

head(sort(as.matrix(tdm.abst[,500]),dec=T))

################################################ Multiplicacion query * tdm (abstracts) ############################################

mat.abst <- sparseMatrix(i=tdm.abst$i, j=tdm.abst$j, x = tdm.abst$v)
dictionary_abst <- tdm.abst$dimnames$Terms
query.vec.abst <- TermDocumentMatrix(query.limp, 
                                  control = list(dictionary = dictionary_abst,
                                                 wordLengths=c(1, Inf))) 

query.vec.abst <- as.matrix(query.vec.abst)/sqrt(sum(query.vec.abst^2)) #normalizar con ntc el query

vec_abst <- t(mat.abst)%*%query.vec.abst

###################################################  top 15 docs (abstracts) ##################################################
idx_top <- order(vec_abst, decreasing=T)

out_abst <- daux[idx_top,] %>%
  select(id,Title, Date, Sponsor, Abstract) %>%
  cbind(score_abst = sort(vec_abst,decreasing = T)) 

res_abstract <- out_abst %>% head(15)
res_abstract$Abstract <- gsub('<br>','',res_abstract$Abstract)
res_abstract$Title <- gsub('<br>','',res_abstract$Title)
res_abstract$Sponsor <- gsub('<br>','',res_abstract$Sponsor)

###################################################  left joins ##################################################

alpha <- .5

output <- d %>% 
  left_join(out_title[,c('id','score_title')], by = "id") %>%
  left_join(out_abst[,c('id','score_abst')], by = "id") %>%
  mutate(final_score=alpha*score_title+(1-alpha)*score_abst) %>%
  filter(final_score!=0) %>%
  arrange(desc(final_score)) 

res <- output %>% head(15)
res$Abstract <- gsub('<br>','',res$Abstract)
res$Title <- gsub('<br>','',res$Title)
res$Sponsor <- gsub('<br>','',res$Sponsor)
View(res)

##############################################  histograma de discriminacion ##########################################

m <- data.frame(min=min(res$final_score))
ggplot() +
  geom_bar(data=output, mapping=aes(x=final_score)) +
  geom_vline(data=res, aes(xintercept=min(final_score)), color='red')












