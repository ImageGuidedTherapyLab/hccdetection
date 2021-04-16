#install.packages("shiny",repos='http://cran.us.r-project.org')
#install.packages("DT",repos='http://cran.us.r-project.org')
library(shiny)

# @egates1 - best practices for scope ?
# load data outside server so it is added to global environment
# and not loaded with every session connection
# https://shiny.rstudio.com/articles/scoping.html
csv.data <- read.csv("./lesiontraining.csv", header = TRUE,na.strings="")

# set up reactive data for updating reviewed status
# This will persist between sessions!
my.data <- reactiveValues(data=cbind(REVIEWED = F,csv.data))

# Define UI for app that draws a histogram ----
ui <- fluidPage(
  titlePanel("Training Data"),
  # Create a save button
  actionButton("savereview","open next case"),
  # Create a new row for the table.
  DT::dataTableOutput("table")
)


# Define server logic required to draw a histogram ----
server <- function(input, output) {

  # Filter data based on selections
  output$table <- DT::renderDataTable(DT::datatable(
    my.data$data,
    selection = "single"
  ))

  # system call selection for QA
  observeEvent(input$table_rows_selected, {
      system(paste0('echo ',my.data$data$uid[input$table_rows_selected],';vglrun itksnap  -l labelkey.txt -g ',my.data$data$raw[input$table_rows_selected],' -s ', my.data$data$liver[input$table_rows_selected]),wait = F)
      if(!is.na(my.data$data$lesion[input$table_rows_selected])) { system(paste0('echo ',my.data$data$uid[input$table_rows_selected],';vglrun itksnap  -l labelkey.txt -g ',my.data$data$raw[input$table_rows_selected],' -s ', my.data$data$lesion[input$table_rows_selected]),wait = F)}
      #system(paste0('echo ',my.data$data$uid[input$table_rows_selected],';make anonymize/',my.data$data$uid[input$table_rows_selected],'/amiralabel'),wait = F)
   })
  
  observeEvent(input$savereview, {
    if( is.null(input$table_rows_selected ) ) {
        current.row = 0
      } else {
        current.row = input$table_rows_selected
        my.data$data$REVIEWED[current.row] = TRUE
      }
    # select the next row in the table to open next case
    DT::selectRows(DT::dataTableProxy('table'), min(current.row + 1, nrow(my.data$data)))
    # TODO: set displayed page correctly on save reviewd
  })
  
}

# Create Shiny app ----
app = shinyApp(ui = ui, server = server)
runApp(app,host="127.0.0.1", port=2021, launch.browser = FALSE)
# Rscript dataqa.R
# source("dataqa.R")
