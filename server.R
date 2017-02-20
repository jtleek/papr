library(readr)
library(lubridate)
library(googlesheets)
library(rdrop2)
library(tidyr)
library(dplyr)
library(googleAuthR)
library(googleID)
library(shiny)

source("google_api_info.R")

shinyServer(function(input, output,session) {
  
  #recommender
  rec <- function(x = m, row = 1, choice = "exciting and correct"){
    #remove columns we've already seen
    x <- x[,-which(colnames(x) %in% isolate(rv$user_dat$index))]
    if (choice %in% c("exciting and correct","exciting and questionable")){
      return(as.integer(names(head(sort(x[row,]),10))))
    }
    if (choice %in% c("boring and correct","boring and questionable") ){
      return(as.integer(names(tail(sort(x[row,]),11))[1:10]))
    }
  }
  
  #Some constants that can be done outside of the shiny server session. 
  load("./biorxiv_data.Rda") #R dataset of paper info
  load("./rec_matrix.Rda") #R dataset of recommended papers
  token <- readRDS("./papr-drop.rds")
  session_id <- as.numeric(Sys.time())
  level_up <- 4 #Number of papers needed to review to level up. 
  
  #Google authentication details
  options(googleAuthR.scopes.selected = c("https://www.googleapis.com/auth/userinfo.email",
                                          "https://www.googleapis.com/auth/userinfo.profile"))
  
  #Variables that get updated throughout the session. 
  #Need to be wrapped in reactiveValues to make sure their updates propigate
  rv <- reactiveValues(
    login = FALSE,
    person_id = 12345,
    counter = -1,
    user_dat = data.frame(index   = NA,
                          title   = NA,
                          link    = NA,
                          session = NA,
                          result  = NA,
                          person  = NA)
  )
  
  #########################################################################################################
  # Function for rating a given paper. 
  #########################################################################################################
  rate_paper <- function(choice, file_path, rv){
    
    #is this the first time the paper is being run?
    initializing <- choice == "initializing"
    
    #are they deciding?
    deciding <- choice == "deciding"
    
    vals <- dat$index #index of all papers in data
    
    if(initializing){
      new_ind <- sample(vals,1) #Grab our first paper!
    } else if(runif(1)<.5 & !deciding) {
      new_ind <- sample(rec(m,isolate(rv$user_dat$index)[1], choice = choice),1)
      print("using our sweet recommendor")
    } else {
      new_ind <- sample(vals[-which(vals %in% isolate(rv$user_dat$index))],1) #randomly grab a new paper but ignore the just read one
      }
    #Make a new row for our session data. 
    new_row <- data.frame(index   = new_ind,
                          title   = dat$titles[dat$index == new_ind],
                          link    = dat$links[dat$index == new_ind],
                          session = session_id,
                          result  = NA,
                          person  = isolate(rv$person_id))
    
    
    if(initializing){ #If this is the first time we're running the function create the dataframe for session
      rv$user_dat <- new_row #add new empty row the csv
    } else { #If this is a normal rating after initialization append a new row to our session df
      rv$user_dat[1,5] <- choice #Put the last review into the review slot of their data. 
      rv$user_dat <- rbind(new_row, rv$user_dat) #add a new empty row to dataframe. 
    }
    
    write_csv(isolate(rv$user_dat),file_path) #write the csv
    drop_upload(file_path, "shiny/2016/papr/", dtoken = token) #upload to dropbox too.
    return(new_ind)
  }
  
  #########################################################################################################
  
  #Create temp csv that we use to track session
  file_path <- file.path(tempdir(), paste0(round(session_id),".csv"))
  write_csv(isolate(rv$user_dat),file_path)
  
  ## Authentication
  accessToken <- callModule(googleAuth, "gauth_login",
                            login_class = "btn btn-primary",
                            logout_class = "btn btn-primary")
  
  #Goes into google's oauth and pulls down identity 
  userDetails <- reactive({
    validate( need(accessToken(), "not logged in") )
    rv$login <- TRUE #Record the user as logged in
    details <- with_shiny(get_user_info, shiny_access_token = accessToken())  #grab the user info
    rv$person_id <- digest::digest(details$id) #assign the user id to our reactive variable
    details #return user information
  })
  
  # Start datastore and display user's Google display name after successful login
  output$display_username <- renderText({
    validate( need(userDetails(), "getting user details") )
    paste("Welcome,", userDetails()$displayName) #return name after validation
  })

  ## Workaround to avoid shinyaps.io URL problems
  observe({
    if (rv$login) {
      shinyjs::onclick("gauth_login-googleAuthUi",
                       shinyjs::runjs(paste0("window.location.href =", site, ";")))
    }
  })

  #If the user clicks skip paper, load some new stuff. 
  # observeEvent(input$skip,{
  #   choice = "skipped"
  #   ind             = rate_paper(choice,file_path,rv) #select the skip option
  #   output$title    = renderText(dat$titles[ind])
  #   output$abstract = renderText(dat$abstracts[ind])
  #   output$authors  = renderText(dat$authors[ind])
  #   output$link     = renderUI({ a(href=dat$links[ind],dat$links[ind]) })
  # })
  
  #On the interaction with the swipe card do this stuff
  observeEvent(input$cardSwiped,{
    
    #Get swipe results from javascript
    swipeResults <- input$cardSwiped
    print(swipeResults)       
    
    if(!(swipeResults %in% c("skipped","deciding"))){
      #Send this swipe result to the rating function to get a new index for a new paper
      ind <- rate_paper(swipeResults,file_path,rv)
      print(paste("ind:", ind));
      selection <- dat[ind,] #grab info on new paper
      session$sendCustomMessage(type = "sendingpapers", selection) #send it over to javascript
      rv$counter = rv$counter + 1
    }
    print(rv$counter)
  })
  
  #on each rating or skip send the counter sum to update level info. 
  nextPaper    <- reactive({rv$counter})
  output$level <- renderText(level_func(nextPaper(),level_up))
  output$icon  <- renderUI(icon_func(nextPaper(),level_up))

  
  #Let the user download their data if they so desire. 
  output$download_data <- downloadHandler(
    filename = "my_ratings.csv",
    content = function(file) {
      udat = rv$user_dat %>%
        mutate(result = replace(result, result == "skipped", NA)) %>%
        separate(result,into=c("exciting","questionable"),sep=" and ") %>%
        transmute(title,link,exciting,questionable,session) %>%
        mutate(user_id = session) %>% select(-session)
      write.csv(udat, file)
    }
  )
})


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
