library(shiny)

# Define UI for dataset viewer application
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Abstract Finder"),
  
  sidebarLayout(
    sidebarPanel(
      textInput("word", label = h3("Title, Abstract or Caption:"),'Markov Chain Monte Carlo Bayesian Statistics'),
      p('Repeat words to increase their relevance'),
      p("\nThe alpha value determines the weight of scores:"),
      withMathJax(p('$$\\alpha*Titles+(1-\\alpha)*Abstracts$$')),
      sliderInput("alpha", 
                   label = withMathJax(h4("$$\\alpha \\text{ value}$$")),
                  min=0,max=1,
                   value = .5),
      submitButton("Update View"),
      plotOutput("contPlot")
    ),
    
    
    mainPanel(
      h3(textOutput("word", container = span)),
      tabsetPanel(type="tabs",
                  tabPanel("Summary",dataTableOutput("res")),
                  tabPanel("Details",dataTableOutput("abstracts")),
                  tabPanel("Discrimination", plotOutput("distPlot")),
                  tabPanel("Weights",dataTableOutput("cont"))
      )
    )
  )
))

