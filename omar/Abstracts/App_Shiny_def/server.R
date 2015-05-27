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
                      d[idx_top_title(),] %>%
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
  
  ####
  #### FALLA EN LA LECTURA DEL DATA.FRAME d !!!!
  #### SI SE ARREGLA ESO, LO DEMAS FUNCIONA PERFECTO

  
  #output <- reactive({
   #                   output <- d %>% 
    #                    left_join(out_title()[,c('id','score_title')], by = "id") %>%
     #                   left_join(out_abst()[,c('id','score_abst')], by = "id") %>%
      #                  mutate(final_score=input$alpha*score_title+(1-input$alpha)*score_abst) %>%
       #                 filter(final_score!=0) %>%
        #                select(Title,Abstract,final_score) %>%
         #               arrange(desc(final_score))  })
  
  res <- reactive({
                  res <- output() %>% head(15)
                  res$Abstract <- gsub('<br>','',res$Abstract)
                  res$Title <- gsub('<br>','',res$Title)
                  res$Sponsor <- gsub('<br>','',res$Sponsor) 
                  res})
  
  output$res  <- renderDataTable(options = list(pageLength = 10), output() )
  
  ################################ imprimimos las primeras 10 recomendaciones ############################## 
  
  
  #output$res  <- renderDataTable(options = list(pageLength = 10), res() )
  
 
})
