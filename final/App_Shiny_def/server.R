library(Matrix)
library(dplyr)
library(tm)
library(slam)
library(Rstem)
library(ggplot2)
library(wordcloud)

####################################### lectura del diccionario y la matriz tdm #########################################
#setwd("~/Dropbox/ITAM_Master/Metodos_Analiticos/Final_MA/omar/Abstracts/App_Shiny_def")

load('data/data.Rdata')


shinyServer(function(input, output){
  
  
  ##################################### imprimimos el texto que buscamos ##############################  
  
  output$word <- renderText(input$word)
  
  
  ################################################### query ############################################### 
  
  ## revisamos el query, quitamos stopwords y normalizamos
  query.limp <- reactive({ 
    
    query <- input$word 
    
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
  })     

    #######################################  Multiplicacion query * tdm (title)  ######################## 
  mat.title <- reactive(  sparseMatrix(i=tdm.title$i, j=tdm.title$j, x = tdm.title$v) )
  dictionary_title <- reactive( tdm.title$dimnames$Terms )  
  
  query.vec.title <- reactive({
                  query.vec.title <-TermDocumentMatrix(query.limp(),
                                                       control = list(dictionary = dictionary_title(),
                                                                     wordLengths=c(1, Inf))) 
                  query.vec.title <- as.matrix(query.vec.title)/sqrt(sum(query.vec.title^2)) 
                  query.vec.title})
  
  vec_title <- reactive(t(mat.title())%*%query.vec.title())
  
  ###################################################  top 15 docs (title) ##################################################
  
  idx_top_title <- reactive(order(vec_title(), decreasing=T))  
  
  out_title <- reactive({
                      d_fin[idx_top_title(),] %>%
                      select(id,Title, Date, Sponsor, Abstract) %>%
                      cbind(score_title = sort(vec_title(),decreasing = T)) })
  
  res_title <- reactive({
                      res_title <- out_title() %>% head(15)
                      res_title$Abstract <- gsub('<br>','',res_title$Abstract)
                      res_title$Title <- gsub('<br>','',res_title$Title)
                      res_title$Sponsor <- gsub('<br>','',res_title$Sponsor)
                      res_title})
  
 
    
  #######################################  Multiplicacion query * tdm (abstracts)  ########################   
  
  
  mat.abst <- reactive( sparseMatrix(i=tdm.abst$i, j=tdm.abst$j, x = tdm.abst$v) )
  dictionary_abst <- reactive(tdm.abst$dimnames$Terms)
  
  query.vec.abst <- reactive({
                      query.vec.abst <- TermDocumentMatrix(query.limp(), 
                                                           control = list(dictionary = dictionary_abst(),
                                                                          wordLengths=c(1, Inf))) 
                      
                      query.vec.abst <- as.matrix(query.vec.abst)/sqrt(sum(query.vec.abst^2))  
                      query.vec.abst})
  
  vec_abst <- reactive(t(mat.abst())%*%query.vec.abst())
  
  ###################################################  top 15 docs (abstracts) ##################################################
  
  idx_top_abst <- reactive(order(vec_abst(), decreasing=T))
  
  out_abst <- reactive({
                      out_abst <- daux[idx_top_abst(),] %>%
                        select(id,Title, Date, Sponsor, Abstract) %>%
                        cbind(score_abst = sort(vec_abst(),decreasing = T))  
                      out_abst})
  
  res_abstract <- reactive({
                          res_abstract <- out_abst() %>% head(15)
                          res_abstract$Abstract <- gsub('<br>','',res_abstract$Abstract)
                          res_abstract$Title <- gsub('<br>','',res_abstract$Title)
                          res_abstract$Sponsor <- gsub('<br>','',res_abstract$Sponsor)  
                          res_abstract})
  

  
  ###################################################  left joins ##################################################
  
  
  output_mod <- reactive({
                     output_mod <-  d_fin %>% 
                                left_join(out_title()[,c('id','score_title')], by = "id") %>%
                                left_join(out_abst()[,c('id','score_abst')], by = "id") %>%
                                mutate(final_score=input$alpha*score_title+(1-input$alpha)*score_abst) %>%
                                filter(final_score!=0) %>%
                                arrange(desc(final_score))
                  output_mod$Abstract <- gsub('<br>','',output_mod$Abstract)
                  output_mod$Title <- gsub('<br>','',output_mod$Title)
                  output_mod$Sponsor <- gsub('<br>','',output_mod$Sponsor) 
                  output_mod})
  
  res <- reactive({
                  res <- output_mod() %>%
                    select(Title,score_title,score_abst,final_score)
                  res})
  
  res15 <- reactive({ res() %>%
                        head(15)})
  
  titulos <- reactive({output_mod() %>%
                         mutate(Obs=row_number()) %>%
                         select(Obs,Title,Sponsor)})
  
  abstracts <- reactive({output_mod() %>%
                           mutate(Obs=row_number()) %>%
                         select(Obs,Abstract)})
  


  ################################ imprimimos las primeras 10 recomendaciones ############################## 
  
  
  output$res  <- renderDataTable(options = list(pageLength = 10), res() )
  output$titulos  <- renderDataTable(options = list(pageLength = 10), titulos() )
  output$abstracts  <- renderDataTable(options = list(pageLength = 10), abstracts() )
  
  
  ##############################################  histograma de discriminacion ##########################################
  
  output$distPlot <- renderPlot({ 
    m <- data.frame(min=min(res15()$final_score))
    ggplot() +
      geom_bar(data=output_mod(), mapping=aes(x=final_score),binwidth=.5) +
      geom_vline(data=res15(), aes(xintercept=min(final_score)), color='red')  })
  
  ################################## wordcloud de contribucion de palabras  ################################# 
  
  best <- reactive({ 
    
    best <- function(nmatch = 3, nterm = 5, alpha=.5){
      vq.title <- query.vec.title()
      vq.abst <- query.vec.abst()
      
      outlist <- list()
      
      for(i in 1:nmatch){
        
        v.j.title <- mat.title()[,idx_top_title()[i]]
        v.j.abst <- mat.abst()[,idx_top_abst()[i]]
        
        v1 <- v.j.title*vq.title
        v2 <- v.j.abst*vq.abst
        
        top_contrib_title <- order(v1,decreasing=T)
        top_contrib_abst <- order(v2,decreasing=T)
        
        df.title <- data.frame(term=dictionary_title()[top_contrib_title[1:nterm]], 
                               score_contrib_title=v1[top_contrib_title[1:nterm]],
                               score_contrib_abst=rep(0,nterm) , stringsAsFactors=F) 
        
        df.abst <- data.frame(term=dictionary_abst()[top_contrib_abst[1:nterm]], 
                              score_contrib_title=rep(0,nterm),
                              score_contrib_abst=v2[top_contrib_abst[1:nterm]],stringsAsFactors=F) 
        df <- rbind(df.title,df.abst)
        
        df <- cbind(aggregate(score_contrib_title ~ term, data=df, FUN=sum),
                    score_contrib_abst=aggregate(score_contrib_abst ~ term, data=df, FUN=sum)[,2])
        df$contrib <- input$alpha*df$score_contrib_title+(1-input$alpha)*df$score_contrib_abst
        
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
    
    
    best <- best(nmatch = 15, nterm = length(unique(strsplit(query.limp()$content[[1]]$content," ")[[1]])))
    
  })
  
  
  ################################ imprimimos palabras con sus contribuciones ############################## 
  
  output$cont <- renderDataTable(options = list(pageLength = 5), best() )
  
  output$contPlot <- renderPlot({  
    wordcloud(best()$term,best()$contrib_tot,
              scale=c(5,.2),
              min.freq=0.1,
              ordered.colors=T,
              colors=colorRampPalette(brewer.pal(9,"Set1"))(nrow(best())))  })
  
  
  
  
  
  
 
})
