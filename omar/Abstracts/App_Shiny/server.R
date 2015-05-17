library(shiny)
library(Matrix)
library(dplyr)
library(tm)
library(ggplot2)
library(wordcloud)

####################################### lectura del diccionario y la matriz tdm #########################################
#setwd("~/Dropbox/ITAM_Master/Metodos_Analiticos/Final_MA/omar/Abstracts/App_Shiny")

load('data/tdm_2.Rdata')
load('data/d.Rdata')
load('data/d_sin_stem.Rdata')

shinyServer(function(input, output) {

  
##################################### imprimimos el texto que buscamos en el diccionario ##############################  
  
output$word <- renderText(input$word)

################################ guardamos variables que necesitaremos para los calculos ############################## 

mat.1 <- reactive(  sparseMatrix(i=tdm.2$i, j=tdm.2$j, x = tdm.2$v) )

dictionary <- reactive( tdm.2$dimnames$Terms )

## revisamos el query, quitamos stopwords y normalizamos
query.limp <- reactive({ 
   
  query <- input$word 
  
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
  
})  

  
query.vec.norm <- reactive({  
  query.vec.1 <- TermDocumentMatrix(query.limp(), 
                                    control = list(dictionary = dictionary(),
                                                   wordLengths=c(1, Inf)))  
  query.vec.norm <- as.matrix(query.vec.1)/sqrt(sum(query.vec.1^2))  
})


mult <- reactive(t(mat.1())%*%query.vec.norm())

idx_top <- reactive(order(mult(), decreasing=T))


out <- reactive({  
  out <- d[idx_top(),] %>%
    select(Title, Date, Sponsor, Abstract) %>%
    cbind(score = sort(mult(),decreasing = T)) %>%
    filter(score > 0)  
})


top15 <- reactive({
  top15 <- out()
  top15$Abstract <- gsub('<br>','',top15$Abstract)
  top15$Title <- gsub('<br>','',top15$Title)
  top15$Sponsor <- gsub('<br>','',top15$Sponsor)
  top15
})

top15_d <- reactive({
  top15 <- out()
  top15$Abstract <- gsub('<br>','',top15$Abstract)
  top15$Title <- gsub('<br>','',top15$Title)
  top15$Sponsor <- gsub('<br>','',top15$Sponsor)
  top15_d <- top15 %>% head(15)
  top15_d
})


################################ imprimimos las primeras 10 recomendaciones ############################## 


output$res  <- renderDataTable(options = list(pageLength = 10), top15() )

###################################### histograma de ajuste del calculo  ################################# 


output$distPlot <- renderPlot({ 
  m <- data.frame(min=min(top15_d()$score))
  ggplot() +
    geom_bar(data=out(), mapping=aes(x=score),binwithd=.5) +
    geom_vline(data=top15_d(), aes(xintercept=min(score)), color='red')
})





################################## wordcloud de contribucion de palabras  ################################# 

best <- reactive({
  
  best <- function(nmatch = 3, nterm = 5){
    
    v.q <- query.vec.norm()
    outlist <- list()
    
    for(i in 1:nmatch){
      
      v.j <- mat.1()[,idx_top()[i]]
      v <- v.j*v.q
      
      top_contrib <- order(v, decreasing = T)
      
      outlist[[i]] <- data.frame(term=dictionary()[top_contrib[1:nterm]],
                                 score_contrib=v[top_contrib[1:nterm]], 
                                 stringsAsFactors=F) %>%
        filter(score_contrib > 0) %>%
        data.frame(rank = i, 
                   match = colnames(tdm.2)[idx_top()[i]], 
                   total_score = sum(v), 
                   stringsAsFactors = F)
    }
    
    
    rbind_all(outlist)[c(3,4,5,1,2)] %>%
      group_by(term) %>%
      summarise(contrib=sum(score_contrib)) %>%
      arrange(desc(contrib))
  }
  
  best <- best(nmatch = 15, nterm = nrow(unique(as.data.frame(strsplit(as.character(input$word[[1]])," ")[[1]])))) 
  best
}) 


################################ imprimimos palabras con sus contribuciones ############################## 


output$cont  <- renderDataTable(options = list(pageLength = 5), best() )
  
output$contPlot <- renderPlot({  
  wordcloud(best()$term,best()$contrib,
            scale=c(9,.8),
            min.freq=0.1,
            ordered.colors=T,
            colors=colorRampPalette(brewer.pal(9,"Set1"))(nrow(best())))
  
})






})











