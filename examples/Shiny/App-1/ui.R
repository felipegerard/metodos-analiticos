
setwd('/Users/Felipe/Dropbox/R/Shiny')
library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  titlePanel('Mi titulo :D'),
  
  sidebarLayout(
    position = 'left',
    sidebarPanel(
      'Sidebar panel',
      helpText('Este texto te ayuda'),
      selectInput('lista1','Choose a variable to display',
                  choices = list('a','b','c'), selected='b'
      ),
      sliderInput('slider1', 'Range of interest', min = 0, max = 100, value=75)
    ),
    mainPanel(
      h1('Titulo de primer nivel'),
      p('Aqui va algo de texto en un parrafo y bla hahaj kalsadf skdf  ajsjsjdfdj jkdjd  jk jk j sa'),
      img(src='query1.png', height=200, width=500)
    )
  )
))