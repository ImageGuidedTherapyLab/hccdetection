library(shiny)

# Define UI for app that draws a histogram ----
ui <- fluidPage(
  titlePanel("Basic DataTable"),
  # Create a new row for the table.
  DT::dataTableOutput("table")
)


# Define server logic required to draw a histogram ----
server <- function(input, output) {

  # @egates1 - best practices for scope ?
  my.data <- read.csv("LiverMRIProjectData/wideanon.csv", header = TRUE)

  # Filter data based on selections
  output$table <- DT::renderDataTable(DT::datatable(
    my.data 
  ))

  # system call selection for QA
  observeEvent(input$table_rows_selected, 
      system(paste0('echo amira  ',my.data$UID[input$table_rows_selected],'.nii.gz'),wait = T)
    )

}

# Create Shiny app ----
app = shinyApp(ui = ui, server = server)
runApp(app,host="127.0.0.1", port=2021, launch.browser = FALSE)
# Rscript dataqa.R
# source("dataqa.R")
