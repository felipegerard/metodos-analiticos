
library(Matrix)
library(dplyr)
library(tm)
library(ggplot2)
library(wordcloud)

#load('output/gutenberg_data_frame.Rdata')
View(dict_df)

#filter(d, Word == 'fish')$Def

d <- dict_df %>%
  filter(grepl('^[a-z]', Word), id != 'Metadata', Def != '')
dim(d)
corpus.frases <- Corpus(VectorSource(d$Def))
corpus.frases
corp.1 <- tm_map(corpus.frases,  function(x){
  gsub('--|[«»\\\',;:".!¡¿?\\(\\)\\[\\]&0-9\\*#/]|<br>','',x) # Checar escapes de &*[]
})

corp.2 <- tm_map(corp.1, function(x) stripWhitespace(x) %>% tolower %>% PlainTextDocument)

tdm.1 <- TermDocumentMatrix(corp.2, control=list(wordLengths=c(1, Inf)))
tdm.2 <- weightSMART(tdm.1, spec = 'ntc')
colnames(tdm.2) <- paste(d$Word, d$id, sep='_')
#sum(rownames(tdm.2) == 'fish-tackle')


## checamos normalización:
head(sort(vec.1 <- as.matrix(tdm.2[,'action_1']),dec=T))


############ Query + Stats

mat.1 <- sparseMatrix(i=tdm.2$i, j=tdm.2$j, x = tdm.2$v)
dictionary <- tdm.2$dimnames$Terms
query.vec.1 <- TermDocumentMatrix(Corpus(VectorSource('i would like to go to the green park on monday')), 
                                  control = list(dictionary = dictionary,wordLengths=c(1, Inf))) 
query.vec.norm <- as.matrix(query.vec.1)/sqrt(sum(query.vec.1^2))
#query.vec.norm <- weightSMART(query.vec.1, spec='ntc', control = list(dictionary = dictionary))
aa <- t(mat.1)%*%query.vec.norm

# Output del query
idx_top <- order(aa, decreasing=T)
out <- d[idx_top,] %>%
  select(Word, id, Def) %>%
  cbind(score = sort(aa,decreasing = T)) %>%
  filter(score > 0)
res <- out %>% head(15)
m <- data.frame(min=min(res$score))
# Estadísticas. Son sobresalientes las palabras que mostramos?
ggplot() +
  geom_bar(data=out, mapping=aes(x=score)) +
  geom_vline(data=res, aes(xintercept=min(score)), color='red')
View(res)

# Qué palabras contribuyeron más al match?

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


best <- best(nmatch = 15, nterm = 10)
wordcloud(best$term,best$contrib,min.freq=0.1,ordered.colors=T,colors=colorRampPalette(brewer.pal(9,"Set1"))(nrow(best)))











