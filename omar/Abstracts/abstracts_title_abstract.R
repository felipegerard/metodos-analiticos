
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
#View(abstracts2)
#colnames(abstracts2)
#nrow(abstracts2)


###################################  limpieza de la informacion y creacion del corpus ##################################

# filtramos cosas feas en abstract y title
d <- abstracts2 %>%
  filter(grepl('Presidential Awardee',Title)=='FALSE') %>% #815
  filter(grepl('Not Available',Abstract)=='FALSE') %>% #1267
  filter(Title != '') %>% #8
  filter(Abstract != '' ) %>% #2180
  filter(grepl('-----------------------------------------------------------------------',Abstract)=='FALSE') %>%
  mutate(id=row_number()) %>%
  select(id,Title,Abstract,Fld.Applictn,Date,Sponsor,Investigator,Award.Number)
#save(d,file='App_Shiny/data/d.Rdata')

# creamos el corpus y limpiamos caracteres especiales del titulo
corpus.frases <- Corpus(VectorSource(d$Title))
#corpus.frases
corpus.frases


corp.1 <- tm_map(corpus.frases,function(x){
  c1 <- gsub('[-]|<br>',' ',x)
  gsub('[()]|[.,;:`"*#&/><]|[\\\']|[]\\[]','',c1)
})

#corp.1$content[1000:1200]


corp.2 <- tm_map(corp.1,removeWords,stopwords("english"))
corp.2 <- tm_map(corp.2, function(x) stripWhitespace(x) %>% tolower)
corp.2 <- tm_map(corp.2,function(x){
  z <- strsplit(x, " +")[[1]]
  z.stem <- wordStem(z, language="english")
  PlainTextDocument(paste(z.stem, collapse=" "))
})

#corp.2$content[1000:1200]

d$Title[7220]


############################  Creacion de la matriz terminos documentos y los pesos por ntc ############################

#creamos la matriz terminos documentos
tdm.1 <- TermDocumentMatrix(corp.2, control=list(wordLengths=c(2, Inf)))
colnames(tdm.1) <- seq(1,tdm.1$ncol)

#eliminamos los documentos que no tienen terminos (empty docs)
#idx_sum <- as.numeric(as.matrix(rollup(tdm.1, 1, na.rm=TRUE, FUN = sum)))
#tdm_new <- tdm.1[,idx_sum>0]

#actualizamos los pesos
#tdm.2 <- weightSMART(tdm_new, spec = 'ntc')
#save(tdm.2,file='App_Shiny/data/tdm_2.Rdata')
tdm.2 <- weightSMART(tdm.1, spec = 'ntc')
#####################################  revisamos la normalizacion de los pesos #########################################

head(sort(vec.1 <- as.matrix(tdm.2[,500]),dec=T))


########################################################  Query #######################################################

query <- 'Polarity Transistion Studies in the Waianae Volcano: From the Gilbert-Gauss to<br> the Upper Kaena Reversals'
query <- 'Markov Chain Monte Carlo'
query  <- 'MCMC'

#limpieza del query
query.l <- Corpus(VectorSource(query))
q.1 <- tm_map(query.l,function(x){
  q1 <- gsub('[-]|<br>',' ',x)
  gsub('[()]|[.,;:`"*#&/><]|[\\\']|[]\\[]','',q1)
})
q.2 <- tm_map(q.1,removeWords,stopwords("english"))
q.2 <- tm_map(q.2, function(x) stripWhitespace(x) %>% tolower)
q.2 <- tm_map(q.2,function(x){
  z <- strsplit(x, " +")[[1]]
  z.stem <- wordStem(z, language="english")
  PlainTextDocument(paste(z.stem, collapse=" "))
})
query.limp <- q.2
#query.limp[[1]]

################################################ Multiplicacion query * tdm ############################################

mat.1 <- sparseMatrix(i=tdm.2$i, j=tdm.2$j, x = tdm.2$v)
dictionary <- tdm.2$dimnames$Terms
query.vec.1 <- TermDocumentMatrix(query.limp, 
                                  control = list(dictionary = dictionary,
                                                 wordLengths=c(1, Inf))) 

query.vec.norm <- as.matrix(query.vec.1)/sqrt(sum(query.vec.1^2)) #normalizar con ntc el query

aa <- t(mat.1)%*%query.vec.norm

###################################################  top 15 docs ##################################################
idx_top <- order(aa, decreasing=T)
d1 <- subset(d,id %in% idx_top)
out <- d1[idx_top,] %>%
  select(id,Title, Date, Sponsor, Abstract) %>%
  cbind(score_title = sort(aa,decreasing = T)) #%>%
  #filter(score_title > 0)

res_title <- out %>% head(15)
res_title$Abstract <- gsub('<br>','',res_title$Abstract)
res_title$Title <- gsub('<br>','',res_title$Title)
res_title$Sponsor <- gsub('<br>','',res_title$Sponsor)
###################################################  corups abstracts ##################################################

daux <- d %>%
  mutate(a=gsub('[-]|<br>',' ',Abstract),
         a=gsub('[()]|[.,;:`"*#&/><]|[\\\']|[]\\[]','',a),
         a=gsub(' +',' ',a),
         a=gsub('^ | $','',a)) %>%
  filter(a != ' ' , a != '', !grepl('(^([^ ] )+[^ ]$)|(^NA$)|(R o o t)', a))
aux <- daux$a

# creamos el corpus y limpiamos caracteres especiales
corpus.frases <- Corpus(VectorSource(aux))
#corpus.frases


corp.2 <- tm_map(corpus.frases,removeWords,stopwords("english"))
corp.2 <- tm_map(corp.2, function(x) stripWhitespace(tolower(x)))
corp.2 <- tm_map(corp.2,function(x){
  z <- strsplit(x, " +")[[1]]
  z.stem <- wordStem(z, language="english")
  PlainTextDocument(paste(z.stem, collapse=" "))
})


nrow(d)
ncol(tdm.1)
############################  Creacion de la matriz terminos documentos y los pesos por ntc ############################

#creamos la matriz terminos documentos
tdm.1 <- TermDocumentMatrix(corp.2, control=list(wordLengths=c(3, Inf)))
colnames(tdm.1) <- seq(1,tdm.1$ncol)

#eliminamos los documentos que no tienen terminos (empty docs)
# idx_sum <- as.numeric(as.matrix(rollup(tdm.1, 1, na.rm=TRUE, FUN = sum)))
# tdm_new <- tdm.1[,idx_sum>0]

#actualizamos los pesos
#tdm.2 <- weightSMART(tdm_new, spec = 'ntc')
#save(tdm.2,file='App_Shiny/data/tdm_2.Rdata')
tdm.2 <- weightSMART(tdm.1, spec = 'ntc')
#####################################  revisamos la normalizacion de los pesos #########################################

head(sort(vec.1 <- as.matrix(tdm.2[,500]),dec=T))

################################################ Multiplicacion query * tdm ############################################

mat.1 <- sparseMatrix(i=tdm.2$i, j=tdm.2$j, x = tdm.2$v)
dictionary <- tdm.2$dimnames$Terms
query.vec.1 <- TermDocumentMatrix(query.limp, 
                                  control = list(dictionary = dictionary,
                                                 wordLengths=c(1, Inf))) 

query.vec.norm <- as.matrix(query.vec.1)/sqrt(sum(query.vec.1^2)) #normalizar con ntc el query

aa <- t(mat.1)%*%query.vec.norm

###################################################  top 15 docs ##################################################
idx_top <- order(aa, decreasing=T)

out_1 <- daux[idx_top,] %>%
  select(id,Title, Date, Sponsor, Abstract) %>%
  cbind(score_abst = sort(aa,decreasing = T)) #%>%
  #filter(score_abst > 0)
res_abstract <- out_1 %>% head(15)
res_abstract$Abstract <- gsub('<br>','',res_abstract$Abstract)
res_abstract$Title <- gsub('<br>','',res_abstract$Title)
res_abstract$Sponsor <- gsub('<br>','',res_abstract$Sponsor)
View(res_abstract)

###################################################  left joins ##################################################

alpha <- .5



output <- d %>% 
  left_join(out[,c('id','score_title')], by = "id") %>%
  left_join(out_1[,c('id','score_abst')], by = "id") %>%
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
# Estadísticas. Son sobresalientes las palabras que mostramos?
ggplot() +
  geom_bar(data=output, mapping=aes(x=final_score)) +
  geom_vline(data=res, aes(xintercept=min(final_score)), color='red')




