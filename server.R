library(readr)
library(lubridate)
library(googlesheets)
library(rdrop2)
library(tidyr)
library(dplyr)
library(googleAuthR)
library(googleID)
library(shiny)

#Some constants that can be done outside of the shiny server session. 
dat <- read_csv("./full_biorxiv_data.csv") #CSV of paper info
token <- readRDS("./papr-drop.rds")
session_id <- as.numeric(Sys.time())
level_up <- 3 #Number of papers needed to review to level up. 

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

shinyServer(function(input, output,session) {
  
  ## Authentication
  accessToken <- callModule(googleAuth, "gauth_login",
                            login_class = "btn btn-primary",
                            logout_class = "btn btn-primary")
  
  #Goes into google's oauth and pulls down identity 
  userDetails <- reactive({
    validate( need(accessToken(), "not logged in") )
    rv$login <- TRUE #Record the user as logged in
    details <- with_shiny(get_user_info, shiny_access_token = accessToken())  #grab the user info
    rv$person_id <- details$id #assign the user id to our reactive variable
    details #return user information
  })
  
  # Display user's Google display name after successful login
  output$display_username <- renderText({
    validate( need(userDetails(), "getting user details") )
    userDetails()$displayName #return name after validation
  })

  ## Workaround to avoid shinyaps.io URL problems
  observe({
    if (rv$login) {
      shinyjs::onclick("gauth_login-googleAuthUi",
                       shinyjs::runjs("window.location.href = 'https://lucy.shinyapps.io/papr';"))
    }
  })

  
  npapers = dim(dat)[1]

  #Create temp csv that we use to track session
  file_path <- file.path(tempdir(), paste0(round(session_id),".csv"))
  write_csv(isolate(rv$user_dat),file_path)

  #Function to sit and watch out swipeinput for decisions on papers.
  observeEvent(input$myswiper,{

    #we need to extract the event we saw from the input passed to shiny from javascript
    #This comes in the form "<choice>,<event number>"
    choice = strsplit(input$myswiper, split = ",")[[1]][1]
    #print(choice) #for debugging purposes.
    
    #Send our choice to the rate_paper function which will then send us back a new abstract index to load a new paper with.
    ind <- rate_paper(choice,file_path,rv)
    # print(dat$abstracts[ind])

    #After we've made our choice, render a new paper' info.
    rv$counter      = rv$counter + 1
    output$title    = renderText(dat$titles[ind])
    output$abstract = renderText(dat$abstracts[ind])
    output$authors  = renderText(dat$authors[ind])
    output$link     = renderUI({ a(href=dat$links[ind],dat$links[ind]) })
    # print(rv$counter) #for debugging purposes
  })

  #If the user clicks skip paper, load some new stuff. 
  observeEvent(input$skip,{
    ind             = rate_paper(button=5,file_path,rv) #select the skip option
    output$title    = renderText(dat$titles[ind])
    output$abstract = renderText(dat$abstracts[ind])
    output$authors  = renderText(dat$authors[ind])
    output$link     = renderUI({ a(href=dat$links[ind],dat$links[ind]) })
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
        separate(result,into=c("exciting","questionable"),sep="_") %>%
        transmute(title,link,exciting,questionable,session) %>%
        mutate(user_id = session) %>% select(-session)
      write.csv(udat, file)
    }
  )
})


rate_paper <- function(choice, file_path, rv){
  
  #is this the first time the paper is being run?
  initializing <-  choice == "initializing"
  
  vals <- 1:dim(dat)[1] #index of all papers in data
  
  if(initializing){
    new_ind <- sample(vals,1) #Grab our first paper!
  } else {
    new_ind <- sample(vals[-isolate(rv$user_dat$index)],1) #randomly grab a new paper but ignore the just read one
  }
  #Make a new row for our session data. 
  new_row <- data.frame(index   = new_ind,
                        title   = dat$titles[new_ind],
                        link    = dat$links[new_ind],
                        session = session_id,
                        result  = NA,
                        person  = isolate(rv$person_id))
  
  
  if(initializing){ #If this is the first time we're running the function create the dataframe for session
    rv$user_dat <- new_row #add new empty row the csv
  } else { #If this is a normal rating after initialization append a new row to our session df
    rv$user_dat[rv$counter,5] <- choice #Put the last review into the review slot of their data. 
    rv$user_dat <- rbind(rv$user_dat,new_row) #add a new empty row to dataframe. 
  }
  
  write_csv(isolate(rv$user_dat),file_path) #write the csv
  drop_upload(file_path, "shiny/2016/papr/", dtoken = token) #upload to dropbox too.
  return(new_ind)
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
