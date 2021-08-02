#install.packages("shiny",repos='http://cran.us.r-project.org')
#install.packages("DT",repos='http://cran.us.r-project.org')
library(shiny)

args <- commandArgs( trailingOnly = TRUE )
portnumber  <- 2021
if( length( args ) >= 1 )
  {
  portnumber  <- as.numeric( args[1] )
  }

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
      #system(paste0('echo ',my.data$data$UID[input$table_rows_selected],';make anonymize/',my.data$data$UID[input$table_rows_selected],'/amiralabel'),wait = F)
      system(paste0('echo ',my.data$data$liver[input$table_rows_selected],';vglrun itksnap  -l labelkey.txt -g ',my.data$data$raw[input$table_rows_selected],' -s ', my.data$data$liver[input$table_rows_selected]),wait = F)
      splitpath = unlist(strsplit(toString(my.data$data$liver[input$table_rows_selected]), '\\.'))
      splitbase = unlist(strsplit(splitpath[1], '\\/'))
      system(paste0('echo ',my.data$data$liver[input$table_rows_selected],';vglrun /opt/apps/Amira/2020.2/bin/start -tclcmd \" load ',my.data$data$raw[input$table_rows_selected],'; load ', my.data$data$liver[input$table_rows_selected],'; create HxCastField ConvertImage; ConvertImage data connect ',splitbase[3 ],'.liver.nii.gz; ConvertImage fire; ConvertImage outputType setIndex 0 7; ConvertImage create result setLabel ; ',splitbase[3 ],'.liver.nii.to-labelfield-8_bits ImageData connect ',splitbase[3 ],'.raw.nii.gz;\"'),wait = F)
      if(!is.na(my.data$data$lesion[input$table_rows_selected])) { system(paste0('echo ',my.data$data$train[input$table_rows_selected],';vglrun itksnap  -l labelkey.txt -g ',my.data$data$longreg[input$table_rows_selected],' -s ', my.data$data$lesion[input$table_rows_selected]),wait = F)}
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
runApp(app,host="127.0.0.1", port=portnumber, launch.browser = FALSE)
# Rscript dataqa.R
# source("dataqa.R")
