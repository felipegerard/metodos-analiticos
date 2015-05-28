
library(Matrix)
library(dplyr)
library(tm)
library(slam)
library(Rstem)
library(ggplot2)
library(wordcloud)

#install.packages("Rstem", repos = "http://www.omegahat.org/R", type="source")

################################################  lectura de la informacion ###########################################


setwd("/Users/lechuga/data-science/metodos-analiticos/omar/Abstracts")
#cargamos los datos
load('abstracts_clean.Rdata')
abstracts2 <- as.data.frame(abstracts2)
View(abstracts2)
colnames(abstracts2)
nrow(abstracts2)

###################################  limpieza de la informacion y creacion del corpus ##################################

# filtramos cosas feas en abstract y title, es decir nos quedamos con los datos 100% limpios
d <- abstracts2 %>%
  filter(grepl('Presidential Awardee',Title)=='FALSE') %>% #815
  filter(grepl('Not Available',Abstract)=='FALSE') %>% #1267
  filter(Title != '') %>% #8
  filter(Abstract != '' ) %>% #2180
  filter(grepl('-----------------------------------------------------------------------',Abstract)=='FALSE') 
#save(d,file='App_Shiny/data/d.Rdata')


#filtrado de información y última limpieza antes de crear el corpus
d1 <- d %>%
  mutate(id=row_number()) %>%
  select(id,Title,Abstract)
v <- filter(d1,grepl('S u m',Abstract)=='TRUE')
subset(v,id==4550)

subset(d1,id==100)

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

save(corp.2, file = '/Users/lechuga/data-science/metodos-analiticos/andres/corpus.Rdata')
#corp.2$content[10]


############################  Creacion de la matriz terminos documentos y los pesos por ntc ############################

#creamos la matriz terminos documentos  ******Tratar de cambiar la longitud de las palabras****
tdm.1 <- TermDocumentMatrix(corp.2, control=list(wordLengths=c(3, Inf)))
colnames(tdm.1) <- seq(1,tdm.1$ncol)

#eliminamos los documentos que no tienen terminos (empty docs) a través de la suma de las columnas
idx_sum <- as.numeric(as.matrix(rollup(tdm.1, 1, na.rm=TRUE, FUN = sum)))
tdm_new <- tdm.1[,idx_sum>0]

@#actualizamos los pesos
tdm.2 <- weightSMART(tdm_new, spec = 'ntc')
#save(tdm.2,file='App_Shiny/data/tdm_2.Rdata')

#####################################  revisamos la normalizacion de los pesos #########################################

head(sort(vec.1 <- as.matrix(tdm.2[,500]),dec=T))


########################################################  Query #######################################################

query <- 'The main objective of this proposal is better understanding of underlying atomic<br> and molecular processes involved in the microstructural evolution of<br> polycrytalline TiS2 and other powders synthesized using the thi-sol-gel process<br> previously proposed by the P.I. A secondary objective is to investigate the<br> electrochemical properties of the resulted thin layer, the influence of heat<br> treatment and of charging on the particulate microstructure. The effects of<br> particle size, shape, crystallite size, orientation and stoichiometry on the<br> elctrochemical properties and the mechanisms involved in the evolution of the<br> microstructure will be investigated using differential thermal and<br> thermogravimetric analyses, scanning and transmission electron microscopy. <br> If successful, the research may provide a method to synthesize an engineered<br> microstructure with optimal electrochemical properties. Applications include<br> electrochemical batteries. The preliminary test have indicated a dramatic<br> increase of the number of charging cycles for a given reduction in performance'
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

##############################################  extraemos los Fields ##################################################


View(d$Fld.Applictn)

d2 <- unique(gsub('[0-9]','',
                  gsub('NEC','',
                       gsub('<br>','',
                            gsub(' ','_',d$Fld.Applictn)))))

d3 <- as.data.frame(unique(gsub(' $','',
                                gsub('^ ','',
                                     stripWhitespace(gsub('_',' ',
                                                          unlist(strsplit(d2,"___"))))))))

colnames(d3) <- 'Field'
d3 <- arrange(d3,Field)









