library(rdrop2)
library(readr)
library(dplyr)
token <- readRDS("./papr-drop.rds")

shinyApp(
  ui = fluidPage(
    h2("Generate Report"),
    h4("& send data to DropBox"),
    actionButton("go", "Click me!"),
    h2("All users' twitter (or blank if they didn't enter one)"),
    DT::dataTableOutput("table")),
  server = function(input, output, session) {
    tbl <- eventReactive(input$go, {
      files <- drop_dir("shiny/2016/papr/user_dat/", dtoken = token)$path
      tbl <- lapply(files, drop_read_csv, dtoken = token) %>% 
        bind_rows()
      
      tbl_twitter <- tbl %>%
        filter(!is.na(twitter)) 
      
      file_path <- file.path(tempdir(), "twitter.csv")
      write_csv(tbl_twitter, file_path)
      drop_upload(file_path, "shiny/2016/papr/comb_dat", dtoken = token)
      tbl %>%
        select(twitter)
    })
    output$table <- DT::renderDataTable({
      tbl()
      })
  }
)