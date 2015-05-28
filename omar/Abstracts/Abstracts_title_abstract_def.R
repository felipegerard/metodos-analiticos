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

d_fin <- d

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
idx_top_title <- order(vec_title, decreasing=T)
out_title <- d[idx_top_title,] %>%
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
idx_top_abst <- order(vec_abst, decreasing=T)

out_abst <- daux[idx_top_abst,] %>%
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


##############################################  WordCloud ##########################################


best <- function(nmatch = 3, nterm = 5, alpha=.5){
    vq.title <- query.vec.title
    vq.abst <- query.vec.abst
    
    outlist <- list()
    
    for(i in 1:nmatch){
    
        v.j.title <- mat.title[,idx_top_title[i]]
        v.j.abst <- mat.abst[,idx_top_abst[i]]
        
        v1 <- v.j.title*vq.title
        v2 <- v.j.abst*vq.abst
        
        top_contrib_title <- order(v1,decreasing=T)
        top_contrib_abst <- order(v2,decreasing=T)
        
        df.title <- data.frame(term=dictionary_title[top_contrib_title[1:nterm]], 
                              score_contrib_title=v1[top_contrib_title[1:nterm]],
                              score_contrib_abst=rep(0,nterm) , stringsAsFactors=F) 
        
        df.abst <- data.frame(term=dictionary_abst[top_contrib_abst[1:nterm]], 
                              score_contrib_title=rep(0,nterm),
                              score_contrib_abst=v2[top_contrib_abst[1:nterm]],stringsAsFactors=F) 
        df <- rbind(df.title,df.abst)
        
        df <- cbind(aggregate(score_contrib_title ~ term, data=df, FUN=sum),
                score_contrib_abst=aggregate(score_contrib_abst ~ term, data=df, FUN=sum)[,2])
        df$contrib <- alpha*df$score_contrib_title+(1-alpha)*df$score_contrib_abst
        
        outlist[[i]] <- df %>%
          filter(contrib>0) %>%
          mutate(rank=i)
    }
    rbind_all(outlist) %>%
      select(term,contrib,rank) %>%
      group_by(term) %>%
      summarise(contrib_tot=sum(contrib)) %>%
      arrange(desc(contrib_tot))
}


#best <- best(nmatch = 15, nterm = 5, alpha=.5)

best <- best(nmatch = 15, nterm = length(unique(strsplit(query.limp$content[[1]]$content," ")[[1]])))

########################################################  wordcloud ##################################################

wordcloud(best$term,best$contrib_tot,
          scale=c(5,.7),
          min.freq=0.1,
          ordered.colors=T,
          colors=colorRampPalette(brewer.pal(9,"Set1"))(nrow(best)))

###################################################  Info a guardar ##################################################


save(d_fin,tdm.title,tdm.abst,daux,file='App_Shiny_def/data/data.Rdata')


