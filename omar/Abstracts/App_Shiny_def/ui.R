library(shiny)

# Define UI for dataset viewer application
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Abstract Finder"),
  
  sidebarLayout(
    sidebarPanel(
      textInput("word", label = h3("Title, Abstract or Caption:"),'Markov Chain Monte Carlo'),
      p("The aplha value determines the weight of scores"),
      p('(alpha)*Titles+(1-alpha)*Abstracts'),
      sliderInput("alpha", 
                   label = h4("alpha value"),
                  min=0,max=1,
                   value = .5),
      submitButton("Update View")
    ),
    
    
    mainPanel(
      h3(textOutput("word", container = span)),
      tabsetPanel(type="tabs",
                  tabPanel("Recommendation",dataTableOutput("res")),
                  navbarMenu("Details",
                             tabPanel("Titulos",dataTableOutput("titulos")),
                             tabPanel("Abstracts",dataTableOutput("abstracts"))
                             ),
                  tabPanel("Discrimination", plotOutput("distPlot")),
                  navbarMenu("Word Contribution",
                             tabPanel("Wordcloud",plotOutput("contPlot")),
                             tabPanel("Weights",dataTableOutput("cont"))
                  )
      )
    )
  )
))

