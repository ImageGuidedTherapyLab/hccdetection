library(shiny)

# Define UI for app that draws a histogram ----
ui <- fluidPage(
  titlePanel("Training Data"),
  # Create a new row for the table.
  DT::dataTableOutput("table")
)


# Define server logic required to draw a histogram ----
server <- function(input, output) {

  # @egates1 - best practices for scope ?
  my.data <- read.csv("./trainingdata.csv", header = TRUE)

  # Filter data based on selections
  output$table <- DT::renderDataTable(DT::datatable(
    my.data 
  ))


  # system call selection for QA
  observeEvent(input$table_rows_selected, 
      #system(shQuote(paste0('echo vglrun /opt/apps/Amira6.4/bin/start -tclcmd " load ',my.data$image[input$table_rows_selected],'; load ', my.data$image[input$table_rows_selected],'create HxCastField ConvertImage; ConvertImage data connect Truth.nii.gz; ConvertImage outputType setIndex 0 6; ConvertImage create result setLabel; Truth.nii.to-labelfield-8_bits ImageData connect Art.raw.nii.gz; "')),wait = T)
      system(paste0('echo ',my.data$uid[input$table_rows_selected],';vglrun itksnap  -l labelkey.txt -g ',my.data$image[input$table_rows_selected],' -s ', my.data$label[input$table_rows_selected],' -o ',  my.data$pre[input$table_rows_selected],' ', my.data$ven[input$table_rows_selected]),wait = T)
    )
}

# Create Shiny app ----
app = shinyApp(ui = ui, server = server)
runApp(app,host="127.0.0.1", port=2021, launch.browser = FALSE)
# Rscript dataqa.R
# source("dataqa.R")
