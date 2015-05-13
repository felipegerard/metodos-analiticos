library(shiny)
library(Matrix)
library(dplyr)
library(tm)
library(ggplot2)
library(wordcloud)

####################################### lectura del diccionario y la matriz tdm #########################################
load('data/tdm_2.Rdata')
load('data/dictionary.Rdata')


shinyServer(function(input, output) {

  
##################################### imprimimos el texto que buscamos en el diccionario ##############################  
  
output$word <- renderText(input$word)

################################ guardamos variables que necesitaremos para los calculos ############################## 

mat.1 <- reactive(  sparseMatrix(i=tdm.2$i, j=tdm.2$j, x = tdm.2$v) )

dictionary <- reactive( tdm.2$dimnames$Terms )

## revisamos el query, quitamos stopwords y normalizamos
aux <- reactive({ 
   
  query <- input$word 
  
  if(sapply(gregexpr("\\W+", query), length) + 1 == 2) {
    #si la longitud del query es de 1 entonces, buscamos y limpiamos su definicion
    definicion <- paste(query,d[which(d$Word %in% query)[1],]$Def)
    definicion <- gsub('--|[],;:.[]|<br>|[()«»"#*`¿?¡!/&%$=]','',definicion)
    definicion <- tm_map(Corpus(VectorSource(definicion)), function(x) stripWhitespace(x) %>% tolower %>% PlainTextDocument)
    definicion <- tm_map(definicion,removeWords,stopwords("english"))
    aux <- definicion
  }else{
    aux <- tm_map(Corpus(VectorSource(query)),removeWords,stopwords("english"))
  }
})  

  
query.vec.norm <- reactive({  
  query.vec.1 <- TermDocumentMatrix(aux(), 
                                    control = list(dictionary = dictionary(),
                                                   wordLengths=c(1, Inf)))  
  query.vec.norm <- as.matrix(query.vec.1)/sqrt(sum(query.vec.1^2))  
})


mult <- reactive(t(mat.1())%*%query.vec.norm())

idx_top <- reactive(order(mult(), decreasing=T))


out <- reactive({  
  out <- d[idx_top(),] %>%
    select(Word, id, Def) %>%
    cbind(score = sort(mult(),decreasing = T)) %>%
    filter(score > 0)  
})


top15 <- reactive({
  top15 <- out()
  top15$Def <- gsub('<br>','',top15$Def)
  top15
})

top15_d <- reactive({
  top15 <- out()
  top15$Def <- gsub('<br>','',top15$Def)
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

output$contPlot <- renderPlot({
  
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
  
  best <- best(nmatch = 15, nterm = nrow(unique(as.data.frame(strsplit(as.character(aux()[[1]])," ")[[1]])))) 
  
  wordcloud(best$term,best$contrib,
            scale=c(5,.7),
            min.freq=0.1,
            ordered.colors=T,
            colors=colorRampPalette(brewer.pal(9,"Set1"))(nrow(best)))
  
})

})











