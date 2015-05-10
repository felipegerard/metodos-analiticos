library(shiny)
library(Matrix)
library(dplyr)
library(tm)
library(ggplot2)
library(wordcloud)

load('data/tdm_2.Rdata')
load('data/dictionary.Rdata')

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  output$word <- renderText({
    input$word
  })
  
  mat.1 <- reactive({
    mat.1 <- sparseMatrix(i=tdm.2$i, j=tdm.2$j, x = tdm.2$v) 
  })
  
  dictionary <- reactive({
    dictionary <- tdm.2$dimnames$Terms
  })
  
  
  
  query.vec.norm <- reactive({ 
    aux <- tm_map(Corpus(VectorSource(input$word)),removeWords,stopwords("english"))
    query.vec.1 <- TermDocumentMatrix(aux, 
                                      control = list(dictionary = dictionary(),
                                                     wordLengths=c(1, Inf)))  
    query.vec.norm <- as.matrix(query.vec.1)/sqrt(sum(query.vec.1^2))
    ##query.vec.norm <- weightSMART(query.vec.1, spec='ntc', control = list(dictionary = dictionary))   
  })
  
  
  mult <- reactive({
    mult <- t(mat.1())%*%query.vec.norm()
  })
  
  idx_top <- reactive({
    # Output del query
    idx_top <- order(mult(), decreasing=T)
  })
  

  out <- reactive({  
    out <- d[idx_top(),] %>%
      select(Word, id, Def) %>%
      cbind(score = sort(mult(),decreasing = T)) %>%
      filter(score > 0)  
  })
  
  top15 <- reactive({
    top15 <- out() %>% head(15)
    top15$Def <- gsub('<br>','',top15$Def)
    top15
  })
  

  output$res  <- renderTable({ 
    top15()
    })
  
  
  
  ## histograma de ajsute
  output$distPlot <- renderPlot({
      
  m <- data.frame(min=min(top15()$score))
  # Estadísticas. Son sobresalientes las palabras que mostramos?
  ggplot() +
    geom_bar(data=out(), mapping=aes(x=score),binwithd=.5) +
    geom_vline(data=top15(), aes(xintercept=min(score)), color='red')
  })
  
  
  
  ### plot de contribucion de palabras
  output$contPlot <- renderPlot({
      
    best <- function(nmatch = 3, nterm = 5){
      v.q <- query.vec.norm()
      outlist <- list()
      for(i in 1:nmatch){
        #colnames(tdm.2)[idx_top[i]]
        #idx_top[nmatch]
        v.j <- mat.1()[,idx_top()[i]]
        v <- v.j*v.q
        #length(v)
        top_contrib <- order(v, decreasing = T)
        outlist[[i]] <- data.frame(term=dictionary()[top_contrib[1:nterm]], # tdm.2$dimnames$Terms[top_contrib[1]]
                                   score_contrib=v[top_contrib[1:nterm]], stringsAsFactors=F) %>%
          filter(score_contrib > 0) %>%
          data.frame(rank = i, match = colnames(tdm.2)[idx_top()[i]], total_score = sum(v), stringsAsFactors = F)
      }
      rbind_all(outlist)[c(3,4,5,1,2)] %>%
        group_by(term) %>%
        summarise(contrib=sum(score_contrib)) %>%
        arrange(desc(contrib))
    }
  
    best <- best(nmatch = 15, nterm = nrow(unique(as.data.frame(strsplit(input$word," ")[[1]])))) 
    
    wordcloud(best$term,best$contrib,
              scale=c(5,.7),
              min.freq=0.1,
              ordered.colors=T,
              colors=colorRampPalette(brewer.pal(9,"Set1"))(nrow(best)))
    
    })
  
  
   
})