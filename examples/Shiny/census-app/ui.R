
setwd('/Users/Felipe/Dropbox/R/Shiny')
library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  titlePanel('Mi titulo :D'),
  
  sidebarLayout(
    position = 'left',
    sidebarPanel(
      'Sidebar panel',
      helpText('Mapas demograficos de EUA, censo 2010'),
      selectInput('lista1','Grupo demografico',
                  choices = list(Blancos='white',Negros='black',Latinos='hispanic',Asiaticos='asian'), selected='Latinos'
      ),
      sliderInput('slider1', 'Rango de interes', min = 0, max = 100, value=c(0,100))
    ),
    mainPanel(
      plotOutput('mapa')
    )
  )
))