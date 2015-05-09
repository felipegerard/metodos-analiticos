library(shiny)

# Define UI for dataset viewer application
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Words Recommendation"),
  
  # Sidebar with controls to provide a caption, select a dataset,
  # and specify the number of observations to view. Note that
  # changes made to the caption in the textInput control are
  # updated in the output area immediately as you type
  sidebarLayout(
    sidebarPanel(
      textInput("word", "Palabra o Frase:", "Analytic Methods"),
      
      submitButton("Update View")
    ),
    
    
    # Show the caption, a summary of the dataset and an HTML 
    # table with the requested number of observations
    mainPanel(
      h3(textOutput("word", container = span)),
      tabsetPanel(type="tabs",
                  tabPanel("Recommendation",tableOutput("res")),
                  tabPanel("Discrimination", plotOutput("distPlot")),
                  tabPanel("Words Contribution",plotOutput("contPlot"))
                  
                  
                  
                  
                  )
      #h3(textOutput("word", container = span)),
      #tableOutput("res"),
      #plotOutput("distPlot"),
      #plotOutput("contPlot")
    )
  )
))




#mainPanel(
#  tabsetPanel(type = "tabs", 
#              tabPanel("Plot", plotOutput("plot")), 
#              tabPanel("Summary", verbatimTextOutput("summary")), 
#              tabPanel("Table", tableOutput("table"))
#)
#  )
#)





