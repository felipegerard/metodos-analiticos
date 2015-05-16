
library(shiny)
library(maps)
library(mapproj)
source("census-app/helpers.R")
counties <- readRDS("census-app/data/counties.rds")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  output$mapa <- renderPlot({
    dat <- switch(input$lista1,
                  'white'=counties$white,
                  'black'=counties$black,
                  'hispanic'=counties$hispanic,
                  'asian'=counties$asian)
    percent_map(dat, "darkgreen", paste('%',input$lista1), min=input$slider1[1], max=input$slider1[2])
  })
  output$texto1 <- renderText({
    paste('Seleccionaste esto:', input$lista1)
  })
  output$texto2 <-renderText({
    input$slider1
  })
  output$glm1 <- renderPrint({
    summary(glm(am~gear+drat, family=binomial(), data=mtcars))
  })
    
})











