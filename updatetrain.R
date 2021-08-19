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
csv.data <- read.csv("bcmlirads/wideanon.csv", header = TRUE,na.strings="")

qadatafiles=paste0("bcmdata/",csv.data$UID,"/reviewsolution.txt")
qadatainfo <- rep(NA,length(qadatafiles))
for (iii in 1:length(qadatafiles))
{
 if(file.exists(qadatafiles[iii]))
 {
  qadatainfo[iii]<- paste(readLines(qadatafiles[iii]), collapse=" ")
 }
}


# set up reactive data for updating reviewed status
# "FixedNumber","PatientNumber","studynumber"
my.data <- reactiveValues(data=cbind(REVIEWED = F, subset(csv.data,  select = c("UID","Vendor","Status","diagnosticinterval","daysincebaseline","Fixed")),
  QA = qadatainfo,
liradtrain=paste0("bcmlirads/",csv.data$UID,"fixed.train.nii.gz"),
liradtrainExists=file.exists(paste0("bcmlirads/",csv.data$UID,"fixed.train.nii.gz")),
#Prerawlivertrain=paste0("bcmdata/",csv.data$UID,"/Pre.rawlivertrain.nii.gz"),
PrerawlivertrainExists=file.exists(paste0("bcmdata/",csv.data$UID,"/Pre.rawlivertrain.nii.gz")),
#Artrawlivertrain=paste0("bcmdata/",csv.data$UID,"/Art.rawlivertrain.nii.gz"),
ArtrawlivertrainExists=file.exists(paste0("bcmdata/",csv.data$UID,"/Art.rawlivertrain.nii.gz")),
#Venrawlivertrain=paste0("bcmdata/",csv.data$UID,"/Ven.rawlivertrain.nii.gz"),
VenrawlivertrainExists=file.exists(paste0("bcmdata/",csv.data$UID,"/Ven.rawlivertrain.nii.gz")),
#Delrawlivertrain=paste0("bcmdata/",csv.data$UID,"/Del.rawlivertrain.nii.gz"),
DelrawlivertrainExists=file.exists(paste0("bcmdata/",csv.data$UID,"/Del.rawlivertrain.nii.gz")),
#Pstrawlivertrain=paste0("bcmdata/",csv.data$UID,"/Pst.rawlivertrain.nii.gz"),
PstrawlivertrainExists=file.exists(paste0("bcmdata/",csv.data$UID,"/Pst.rawlivertrain.nii.gz")),
Prelongregcc=file.exists(paste0("bcmdata/",csv.data$UID,"/Pre.longregcc.nii.gz")),
Artlongregcc=file.exists(paste0("bcmdata/",csv.data$UID,"/Art.longregcc.nii.gz")),
Venlongregcc=file.exists(paste0("bcmdata/",csv.data$UID,"/Ven.longregcc.nii.gz")),
Dellongregcc=file.exists(paste0("bcmdata/",csv.data$UID,"/Del.longregcc.nii.gz")),
Pstlongregcc=file.exists(paste0("bcmdata/",csv.data$UID,"/Pst.longregcc.nii.gz"))
))

# Define UI for app that draws a histogram ----
ui <- fluidPage(
  titlePanel("Training Data"),
  # Create a save button
  actionButton("savereview","update table "),
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
      system(paste0('echo ',my.data$data$UID[input$table_rows_selected],';make bcmdata/',my.data$data$UID[input$table_rows_selected],'/qabcmlong '),wait = F)
   })
  
  observeEvent(input$savereview, {
    if( !is.null(input$table_rows_selected ) ) {
        current.row = input$table_rows_selected
        my.data$data$REVIEWED[current.row] = TRUE
        DT::reloadData(DT::dataTableProxy('table'), clearSelection = 'all' )
      }
    # select the next row in the table to open next case
    #DT::selectRows(DT::dataTableProxy('table'), min(current.row + 1, nrow(my.data$data)))
    # TODO: set displayed page correctly on save reviewd
  })
  
}

# Create Shiny app ----
app = shinyApp(ui = ui, server = server)
runApp(app,host="127.0.0.1", port=portnumber, launch.browser = FALSE)
# Rscript updatetrain.R 2023
# source("updatetrain.R")
