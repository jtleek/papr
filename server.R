library(readr)
library(lubridate)
library(googlesheets)
library(rdrop2)
library(tidyr)
library(dplyr)
library(googleAuthR)
library(googleID)
library(shiny)

dat   <- read_csv("./full_biorxiv_data.csv")
token <- readRDS("./papr-drop.rds")
session_id <-  as.numeric(Sys.time())

options(googleAuthR.scopes.selected = c("https://www.googleapis.com/auth/userinfo.email",
                                        "https://www.googleapis.com/auth/userinfo.profile"))
rv <- reactiveValues(
  login = FALSE
)
rv$person_id <- 12345

shinyServer(function(input, output,session) {
 
  
  ## Authentication
  accessToken <- callModule(googleAuth, "gauth_login",
                            login_class = "btn btn-primary",
                            logout_class = "btn btn-primary")
  
  #Goes into googles oauth and pulls down identity 
  userDetails <- reactive({
    validate(
      need(accessToken(), "not logged in")
    )
    rv$login <- TRUE
    #grab the user information from google
    details <- with_shiny(get_user_info, shiny_access_token = accessToken())
    #assign the user id to our reactive variable
    rv$person_id <- details$id
    #return user information
    details
  })
  
  # Display user's Google display name after successful login
  output$display_username <- renderText({
    validate(
      need(userDetails(), "getting user details")
    )
    userDetails()$displayName
  })

  ## Workaround to avoid shinyaps.io URL problems
  observe({
    if (rv$login) {
      shinyjs::onclick("gauth_login-googleAuthUi",
                       shinyjs::runjs("window.location.href = 'https://lucy.shinyapps.io/papr';"))
    }
  })


  level_up = 2
  npapers = dim(dat)[1]

  file_path <- file.path(tempdir(), paste0(round(session_id),".csv"))
  values = reactiveValues(counter = -1)
  values$user_dat <- data.frame(index   = NA,
                                title   = NA,
                                link    = NA,
                                session = NA,
                                result  = NA,
                                person  = NA)

  write_csv(isolate(values$user_dat),file_path)

  #Function to sit and watch out swipeinput for decisions on papers.
  observeEvent(input$myswiper,{

    #we need to extract the event we saw from the input passed to shiny from javascript
    #This comes in the form "<choice>,<event number>"
    choice = strsplit(input$myswiper, split = ",")[[1]][1]

    #print(choice) #for debugging purposes.

    if(choice == "exciting and correct"){
      ind = button_func(button=1,file_path,values)
    } else if(choice == "exciting and questionable"){
      ind = button_func(button=2,file_path,values)
    } else if(choice == "boring and correct"){
      ind = button_func(button=3,file_path,values)
    } else if(choice == "boring and questionable"){
      ind = button_func(button=4,file_path,values)
    } else {
      ret = initial_func(file_path,values)
      ind = ret$ind
    }

    print(dat$abstracts[ind])

    #After we've made our choice, render a new paper' info.
    values$counter  = values$counter + 1
    output$title    = renderText(dat$titles[ind])
    output$abstract = renderText(dat$abstracts[ind])
    output$authors  = renderText(dat$authors[ind])
    output$link     = renderUI({
      a(href=dat$links[ind],dat$links[ind])
    })
    print(values$counter)
  })


  observeEvent(input$skip,{
    ind = button_func(button=5,file_path,values)
    output$title =    renderText(dat$titles[ind])
    output$abstract = renderText(dat$abstracts[ind])
    output$authors =  renderText(dat$authors[ind])
    output$link = renderUI({
      a(href=dat$links[ind],dat$links[ind])
    })
  })

  react2 <- reactive({
     buttons = c(values$counter,
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
  button_names <- c("excite_correct",
                    "excite_question",
                    "boring_correct",
                    "boring_question",
                    "skipped_unsure")

  vals = 1:dim(dat)[1]
  new_ind = sample(vals[-isolate(values$user_dat$index)],1)
  click_number = dim(isolate(values$user_dat))[1]
  values$user_dat[click_number,5] <- button_names[button_val]
  new_row = data.frame(index = new_ind,
                       title = dat$titles[new_ind],
                       link = dat$links[new_ind],
                       session = session_id,
                       result = NA,
                       person = isolate(rv$person_id))
  
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
                                result = NA,
                                person = isolate(rv$person_id))
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
