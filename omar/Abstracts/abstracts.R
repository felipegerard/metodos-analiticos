
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
View(abstracts2)
colnames(abstracts2)
nrow(abstracts2)

###################################  limpieza de la informacion y creacion del corpus ##################################

# filtramos cosas feas en abstract y title
d <- abstracts2 %>%
  filter(grepl('Presidential Awardee',Title)=='FALSE') %>% #815
  filter(grepl('Not Available',Abstract)=='FALSE') %>% #1267
  filter(Title != '') %>% #8
  filter(Abstract != '' ) %>% #2180
  filter(grepl('-----------------------------------------------------------------------',Abstract)=='FALSE') 
#save(d,file='App_Shiny/data/d.Rdata')

# consultas de caractres especiales en la info
d1 <- d %>%
  mutate(id=row_number()) %>%
  select(id,Abstract)
v <- filter(d1,grepl('S u m',Abstract)=='TRUE')
subset(v,id==4550)

subset(d1,id==10)

# creamos el corpus y limpiamos caracteres especiales
corpus.frases <- Corpus(VectorSource(d$Abstract))
#corpus.frases

corp.1 <- tm_map(corpus.frases,function(x){
  c1 <- gsub('R o o t E n t<br> r y','Root Entry',x)
  c2 <- gsub('C o m p O b j','Comp Obj',c1)
  c3 <- gsub('S u m m a r y I n f o r m a t i o n','Summary Information',c2)
  c4 <- gsub('<br> b <br>','',c3)
  c5 <- gsub('W o r d D o c u m e n t','Word Document',c4)
  c6 <- gsub('O b j e c t P o o l','Object Pool',c5)
  c7 <- gsub('[-]|<br>',' ',c6)
  gsub('[()]|[.,;:`"*#&/><]|[\\\']|[]\\[]','',c7)
})
corp.2 <- tm_map(corp.1,removeWords,stopwords("english"))
corp.2 <- tm_map(corp.2, function(x) stripWhitespace(x) %>% tolower)
corp.2 <- tm_map(corp.2,function(x){
  z <- strsplit(x, " +")[[1]]
  z.stem <- wordStem(z, language="english")
  PlainTextDocument(paste(z.stem, collapse=" "))
})

#corp.2$content[10]


############################  Creacion de la matriz terminos documentos y los pesos por ntc ############################

#creamos la matriz terminos documentos
tdm.1 <- TermDocumentMatrix(corp.2, control=list(wordLengths=c(3, Inf)))

#eliminamos los documentos que no tienen terminos (empty docs)
idx_sum <- as.numeric(as.matrix(rollup(tdm.1, 1, na.rm=TRUE, FUN = sum)))
tdm_new <- tdm.1[,idx_sum>0]

#actualizamos los pesos
tdm.2 <- weightSMART(tdm_new, spec = 'ntc')
#save(tdm.2,file='App_Shiny/data/tdm_2.Rdata')

#####################################  revisamos la normalizacion de los pesos #########################################

head(sort(vec.1 <- as.matrix(tdm.2[,500]),dec=T))


########################################################  Query #######################################################

query <- 'space users will be<br> utilized to determine space weather impacts to specific systems and how space<br> weather nowcast and forecast products could be utilized by their operations <br> to improve efficiency and effectiveness. Data collected during these visits<br> will be utilized to determine customer needs for space weather bulletins,<br> alerts, warnings, and forecasts.'


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
out <- d[idx_top,] %>%
  select(Title, Date, Sponsor, Abstract) %>%
  cbind(score = sort(aa,decreasing = T)) %>%
  filter(score > 0)
res <- out %>% head(15)
res$Abstract <- gsub('<br>','',res$Abstract)
res$Title <- gsub('<br>','',res$Title)
res$Sponsor <- gsub('<br>','',res$Sponsor)
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

best <- best(nmatch = 15, nterm = nrow(unique(as.data.frame(strsplit(as.character(query[[1]])," ")[[1]]))))


########################################################  wordcloud ##################################################

wordcloud(best$term,best$contrib,
          scale=c(5,.7),
          min.freq=0.1,
          ordered.colors=T,
          colors=colorRampPalette(brewer.pal(9,"Set1"))(nrow(best)))






















