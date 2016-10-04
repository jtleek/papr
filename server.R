library(readr)
library(lubridate)
library(googlesheets)
library(rdrop2)
library(tidyr)
library(dplyr)

dat <- read_csv("./full_biorxiv_data.csv")
token <- readRDS("./papr-drop.rds")
session_id <-  as.numeric(Sys.time())


shinyServer(function(input, output,session) {
  level_up = 2
  npapers = dim(dat)[1]
  
  file_path <- file.path(tempdir(), paste0(round(session_id),".csv"))
  values = reactiveValues()
  values$user_dat <- data.frame(index = NA,
                                title = NA,
                                link = NA,
                                session = NA,
                                result = NA) 
  
  write_csv(isolate(values$user_dat),file_path)
  
  observeEvent(!any(as.logical(input$list)),{
    ret = initial_func(file_path,values)
    values = ret$values
    output$title = renderText(dat$titles[ret$ind])
    output$abstract = renderText(dat$abstracts[ret$ind])
    output$authors = renderText(dat$authors[ret$ind])
    output$link = renderUI({
      a(href=dat$links[ret$ind],dat$links[ret$ind])
    })
  })
  
  observeEvent(input$myswiper == "You swiped right",{
    ind = button_func(button=1,file_path,values)
    output$title = renderText(dat$titles[ind])
    output$abstract = renderText(dat$abstracts[ind])
    output$authors = renderText(dat$authors[ind])
    output$link = renderUI({
      a(href=dat$links[ind],dat$links[ind])
    })
  })
  
  observeEvent(input$myswiper == "You swiped up",{
    ind = button_func(button=2,file_path,values)
    output$title = renderText(dat$titles[ind])
    output$abstract = renderText(dat$abstracts[ind])
    output$authors = renderText(dat$authors[ind])
    output$link = renderUI({
      a(href=dat$links[ind],dat$links[ind])
    })
  })
  
  observeEvent(input$myswiper == "You swiped down",{
    ind = button_func(button=3,file_path,values)
    output$title = renderText(dat$titles[ind])
    output$abstract = renderText(dat$abstracts[ind])
    output$authors = renderText(dat$authors[ind])
    output$link = renderUI({
      a(href=dat$links[ind],dat$links[ind])
    })
  })
  
  observeEvent(input$swiper == "You swiped left",{
    ind = button_func(button=4,file_path,values)
    output$title = renderText(dat$titles[ind])
    output$abstract = renderText(dat$abstracts[ind])
    output$authors = renderText(dat$authors[ind])
    output$link = renderUI({
      a(href=dat$links[ind],dat$links[ind])
    })
  })
  
  observeEvent(input$skip,{
    ind = button_func(button=5,file_path,values)
    output$title = renderText(dat$titles[ind])
    output$abstract = renderText(dat$abstracts[ind])
    output$authors = renderText(dat$authors[ind])
    output$link = renderUI({
      a(href=dat$links[ind],dat$links[ind])
    })
  })
  
  react2 <- reactive({
    buttons = c(input$excite_correct,
                input$excite_question,
                input$boring_correct,
                input$boring_question,
                input$skip)
    return(sum(buttons))
  })
  
  
  output$level = renderText(level_func(react2(),level_up))
  output$icon = renderUI(icon_func(react2(),level_up))
  
  output$download_data <- downloadHandler(
    filename = "my_ratings.csv",
    content = function(file) {
      udat = values$user_dat %>% 
        separate(result,into=c("exciting","questionable"),sep="_") %>%
        transmute(title,link,exciting,questionable,session) %>%
        mutate(user_id = session) %>% select(-session)
      write.csv(udat, file)
    }
  )
})


button_func <- function(button_val,file_path,values){
  button_names <- c("excite_correct","excite_question",
                    "boring_correct","boring_question","skipped_unsure")
  vals = 1:dim(dat)[1]
  new_ind = sample(vals[-isolate(values$user_dat$index)],1)
  click_number = dim(isolate(values$user_dat))[1]
  values$user_dat[click_number,5] <- button_names[button_val]
  new_row = data.frame(index = new_ind,
                       title = dat$titles[new_ind],
                       link = dat$links[new_ind],
                       session = session_id,
                       result = NA) 
  values$user_dat <- rbind(values$user_dat,new_row)
  write_csv(isolate(values$user_dat),file_path)
  drop_upload(file_path,
              "shiny/2016/papr/",
              dtoken = token)
  return(new_ind)
}


initial_func <- function(file_path,values){
  ind = sample(1:dim(dat)[1],size=1)
  values$user_dat <- data.frame(index = ind,
                                title = dat$titles[ind],
                                link = dat$links[ind],
                                session = session_id,
                                result = NA) 
  write_csv(values$user_dat,file_path)
  drop_upload(file_path,
              "shiny/2016/papr/",
              dtoken = token)
  return(list(ind=ind,values=values))
}



level_func = function(x,level_up){
  if(x < level_up){return("Undergrad")}
  if(x == level_up){return("Congrats grad!")}
  if(x < (2*level_up)){return("Grad Student")}
  if(x== (2*level_up)){return("Doctor?...Doctor.")}
  if(x< (3*level_up)){return("Postdoc")}
  if(x == (3*level_up)){return("Booyah tenure track!")}
  if(x < (4*level_up)){return("Assistant Prof")}
  if(x == (4*level_up)){return("Tenure baby!")}
  if(x < (5*level_up)){return("Associate Prof")}
  if(x == (5*level_up)){return("Top of the pile!")}
  if(x > (5*level_up)){return("Full Prof")}
}

icon_func = function(x,level_up){
  if(x < level_up){return(icon("user"))}
  if(x == level_up){return(icon("graduation-cap"))}
  if(x < (2*level_up)){return(icon("graduation-cap"))}
  if(x== (2*level_up)){return(icon("coffee"))}
  if(x< (3*level_up)){return(icon("coffee"))}
  if(x == (3*level_up)){return(icon("briefcase",lib="glyphicon"))}
  if(x < (4*level_up)){return(icon("briefcase",lib="glyphicon"))}
  if(x == (4*level_up)){return(icon("university"))}
  if(x < (5*level_up)){return(icon("university"))}
  if(x == (5*level_up)){return(icon("tower",lib="glyphicon"))}
  if(x > (5*level_up)){return(icon("tower",lib="glyphicon"))}
}


