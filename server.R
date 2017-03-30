library(readr)
library(lubridate)
library(googlesheets)
library(rdrop2)
library(tidyr)
library(dplyr)
library(googleAuthR)
library(googleID)
library(shiny)
library(plotly)
library(shinysense)

source("google_api_info.R")

shinyServer(function(input, output, session) {
  #recommender
  rec <-
    function(x = term_pca_df,
             user_PC = isolate(rv$pc),
             user_dat_index = isolate(rv$user_dat$index),
             index =  isolate(rv$user_dat$index)[1],
             count = isolate(rv$counter),
             choice = "exciting and correct",
             output = "user_PC") {
      #remove columns we've already seen
      if (choice %in% c("exciting and correct", "exciting and questionable")) {
        user_PC <- colMeans(rbind(user_PC, x[x$index == index, 1:3]))/(count+1)
      }
      if (choice %in% c("boring and correct", "boring and questionable")) {
        user_PC <- colMeans(rbind(user_PC,-x[x$index == index, 1:3]))/(count+1)
      }
      if (output == "user_PC") {
        return(user_PC)
      }
      if (output == "recs") {
        x <- x[-which(x$index %in% user_dat_index), ]
        dist <- data_frame(index = x$index, dist = as.vector(sqrt(
          (as.numeric(user_PC[1]) - x[1]) ^ 2 +
            (as.numeric(user_PC[2]) - x[2]) ^ 2 +
            (as.numeric(user_PC[3]) - x[3]) ^ 2
        )))
        recs <- tail(arrange(dist, dist), 10) %>%
          .[['index']] %>%
          unlist() %>%
          as.integer()
        return(recs)
      }
    }
  
  load("./biorxiv_data.Rda") #R dataset of paper info
  load("./term_pca_df.Rda") #R dataset of paper PCA
  token <- readRDS("./papr-drop.rds")
  
  twitter <- drop_read_csv("shiny/2016/papr/comb_dat/twitter.csv", dtoken = token)
  session_id <- as.numeric(Sys.time())
  level_up <- 4 #Number of papers needed to review to level up.
  
  #Google authentication details
  options(
    googleAuthR.scopes.selected = c(
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/userinfo.profile"
    )
  )
  
  #Variables that get updated throughout the session.
  #Need to be wrapped in reactiveValues to make sure their updates propigate
  rv <- reactiveValues(
    login = FALSE,
    terms_accepted = FALSE,
    person_id = 12345,
    counter = -1,
    pc = colMeans(term_pca_df[1:3]),
    user_dat = data.frame(
      index   = NA,
      title   = NA,
      link    = NA,
      session = NA,
      result  = NA,
      person  = NA
    )
  )
  
  #make a popup that alerts the user that we have super important data terms
  #don't show the popup if the user is logged in though. 
  # observe({
  #   # print(paste("running make popup with the value", rv$login))
  #   # make_popup <- callModule(shinypopup, "terms", accepted = rv$terms_accepted)
  # })
  make_popup <- callModule(shinypopup, "terms", accepted = F)
  #########################################################################################################
  # Function for rating a given paper.
  #########################################################################################################
  rate_paper <- function(choice, file_path, rv) {
    #is this the first time the paper is being run?
    initializing <- choice == "initializing"
    
    #are they deciding?
    deciding <- choice == "deciding"
    
    vals <- dat$index #index of all papers in data
    
    if (initializing) {
      new_ind <- sample(vals, 1) #Grab our first paper!
    } else if (runif(1) < .75 & !deciding) {
      new_ind <- sample(rec(choice = choice, output = "recs"), 1)
      rv$pc <- rec(choice = choice, output = "user_PC")
      # print("using our sweet recommendor")
    } else {
      new_ind <-
        sample(vals[-which(vals %in% isolate(rv$user_dat$index))], 1) #randomly grab a new paper but ignore the just read one
      rv$pc <- rec(choice = choice, output = "user_PC")
    }
    #Make a new row for our session data.
    new_row <- data.frame(
      index   = new_ind,
      title   = dat$titles[dat$index == new_ind],
      link    = dat$links[dat$index == new_ind],
      session = session_id,
      result  = NA,
      person  = isolate(rv$person_id)
    )
    
    
    if (initializing) {
      #If this is the first time we're running the function create the dataframe for session
      rv$user_dat <- new_row #add new empty row the csv
    } else {
      #If this is a normal rating after initialization append a new row to our session df
      rv$user_dat[1, 5] <-
        choice #Put the last review into the review slot of their data.
      rv$user_dat <-
        rbind(new_row, rv$user_dat) #add a new empty row to dataframe.
    }
    
    write_csv(isolate(rv$user_dat), file_path) #write the csv
    drop_upload(file_path, "shiny/2016/papr/", dtoken = token) #upload to dropbox too.
    
    file_path2 <-
      file.path(tempdir(), paste0("user_dat_",isolate(rv$person_id), ".csv"))
    write_csv(data.frame(name = isolate(input$name), twitter = isolate(input$twitter), PC1 = isolate(rv$pc[1]), PC2 = isolate(rv$pc[2]), PC3 = isolate(rv$pc[3])), file_path2)
    drop_upload(file_path2,"shiny/2016/papr/user_dat/", dtoken = token)
    
    return(new_ind)
  }
  
  #########################################################################################################
  
  #Create temp csv that we use to track session
  file_path <-
    file.path(tempdir(), paste0(round(session_id), ".csv"))
  write_csv(isolate(rv$user_dat), file_path)
  
  ## Authentication
  accessToken <- callModule(googleAuth,
                            "gauth_login",
                            login_class = "btn btn-primary",
                            logout_class = "btn btn-primary")
  
  #Goes into google's oauth and pulls down identity
  userDetails <- reactive({
    validate(need(accessToken(), "not logged in"))
    
    rv$login <- TRUE #Record the user as logged in

    details <- with_shiny(get_user_info, shiny_access_token = accessToken())  #grab the user info
    rv$person_id <- digest::digest(details$id) #assign the user id to our reactive variable
    if(isolate(rv$person_id) != 12345 & drop_exists(paste0("shiny/2016/papr/user_dat/user_dat_",isolate(rv$person_id),".csv"), dtoken = token)){
      rv$pc <- as.numeric(drop_read_csv(paste0("shiny/2016/papr/user_dat/user_dat_",isolate(rv$person_id),".csv"))[,3:5], dtoken = token)
    }
    details #return user information
  })
  
  # Start datastore and display user's Google display name after successful login
  output$display_username <- renderText({

    validate(need(userDetails(), "getting user details"))
    
    if(rv$login){
      paste("You're logged in with Google!") #return name after validation
    } else {
      "Log in to keep track of rankings!"
    }
  })
  
  #output friends!

  output$friends <- renderText({
    #remove you!
    twitter %>%
      filter(twitter != input$twitter) -> twitter
    #find users closest to you
    
    friend_dist <- data.frame(name = as.character(twitter$name), twitter = as.character(twitter$twitter), dist = as.vector(sqrt(
      (as.numeric(rv$pc[1]) - twitter[,"PC1"]) ^ 2 +
        (as.numeric(rv$pc[2]) - twitter[,"PC2"]) ^ 2 +
        (as.numeric(rv$pc[3]) - twitter[,"PC3"]) ^ 2
    )), stringsAsFactors = FALSE)
    friend_handle <- arrange(friend_dist,dist)[1:5,2]
    friend_name <- arrange(friend_dist,dist)[1:5,1]
    friend_handle <- friend_handle[complete.cases(friend_handle)]
    friend_name <- friend_name[complete.cases(friend_name)]
    follow <- function(who, where){
      paste0(who,
             ": <a href='https://twitter.com/",
             where,
             "' class='twitter-follow-button' data-show-count='false'>Follow @",
             where,
             "</a><script async src='//platform.twitter.com/widgets.js' charset='utf-8'></script><br>")
    }
    follow(friend_name,friend_handle)
       })
  
  ## Workaround to avoid shinyaps.io URL problems
  observe({
    if (rv$login) {
      shinyjs::onclick("gauth_login-googleAuthUi",
                       shinyjs::runjs(paste0("window.location.href =", site, ";")))
    }
  })
  

  #On the interaction with the swipe card do this stuff
  observeEvent(input$cardSwiped, {
    #Get swipe results from javascript
    swipeResults <- input$cardSwiped
    # print(swipeResults)
    
    if (!(swipeResults %in% c("skipped", "deciding"))) {
      #Send this swipe result to the rating function to get a new index for a new paper
      ind <- rate_paper(swipeResults, file_path, rv)
      # print(paste("ind:", ind))
      
      selection <- dat[ind, ] #grab info on new paper
      session$sendCustomMessage(type = "sendingpapers", selection) #send it over to javascript
      rv$counter = rv$counter + 1
    }
    print(rv$counter)
  })
  
  #on each rating or skip send the counter sum to update level info.
  nextPaper    <- reactive({
    rv$counter
  })
  output$level <- renderText(level_func(nextPaper(), level_up))
  output$icon  <- renderUI(icon_func(nextPaper(), level_up))
  
  
  #Let the user download their data if they so desire.
  output$download_data <- downloadHandler(
    filename = "my_ratings.csv",
    content = function(file) {
      udat = rv$user_dat %>%
        mutate(result = replace(result, result == "skipped", NA)) %>%
        separate(result,
                 into = c("exciting", "questionable"),
                 sep = " and ") %>%
        transmute(title, link, exciting, questionable, session) %>%
        mutate(user_id = session) %>% select(-session)
      write.csv(udat, file)
    }
  )
  
  #PCA plot
  output$plotly <- renderPlotly({
    user_pc_df <- data_frame(PC1 = rv$pc[1],
                             PC2 = rv$pc[2],
                             PC3 = rv$pc[3], 
                             PC4 = NA,
                             PC5 = NA,
                             titles = "Your Average",
                             index = 999999)
    rbind(user_pc_df, term_pca_df) %>%
      mutate(
        color = ifelse(titles == "Your Average", "purple", "lightblue"),
        size = ifelse(titles == "Your Average", 20, 5)
      ) -> test_pca
    
    plot_ly(
      test_pca,
      x = ~ PC1,
      y = ~ PC2,
    #  z = ~ PC3,
      text = ~ paste('Title:', titles),
      marker = list(
        mode = "marker",
        color = ~ color,
        size = ~ size,
        opacity = 0.25
      )
    ) %>%
      add_markers(name = "Click here to hide/show all papers") %>%
      add_trace(
        x = as.numeric(test_pca[1, 1]),
        y = as.numeric(test_pca[1, 2]),
      # z = as.numeric(test_pca[1, 3]),
      # type = "scatter3d",
        type = "scatter",
        text = "You are here",
        mode = "text",
        name = "Click here to hide/show your location"
      ) %>%
      layout(scene = list(
        xaxis = list(title = 'PC1'),
        yaxis = list(title = 'PC2')
       # zaxis = list(title = 'PC3')
      ))
  })
})


level_func = function(x, level_up) {
  if (x < level_up) {
    return("Undergrad")
  }
  if (x == level_up) {
    return("Congrats grad!")
  }
  if (x < (2 * level_up)) {
    return("Grad Student")
  }
  if (x == (2 * level_up)) {
    return("Doctor?...Doctor.")
  }
  if (x < (3 * level_up)) {
    return("Postdoc")
  }
  if (x == (3 * level_up)) {
    return("Booyah tenure track!")
  }
  if (x < (4 * level_up)) {
    return("Assistant Prof")
  }
  if (x == (4 * level_up)) {
    return("Tenure baby!")
  }
  if (x < (5 * level_up)) {
    return("Associate Prof")
  }
  if (x == (5 * level_up)) {
    return("Top of the pile!")
  }
  if (x > (5 * level_up)) {
    return("Full Prof")
  }
}

icon_func = function(x, level_up) {
  if (x < level_up) {
    return(icon("user"))
  }
  if (x == level_up) {
    return(icon("graduation-cap"))
  }
  if (x < (2 * level_up)) {
    return(icon("graduation-cap"))
  }
  if (x == (2 * level_up)) {
    return(icon("coffee"))
  }
  if (x < (3 * level_up)) {
    return(icon("coffee"))
  }
  if (x == (3 * level_up)) {
    return(icon("briefcase", lib = "glyphicon"))
  }
  if (x < (4 * level_up)) {
    return(icon("briefcase", lib = "glyphicon"))
  }
  if (x == (4 * level_up)) {
    return(icon("university"))
  }
  if (x < (5 * level_up)) {
    return(icon("university"))
  }
  if (x == (5 * level_up)) {
    return(icon("tower", lib = "glyphicon"))
  }
  if (x > (5 * level_up)) {
    return(icon("tower", lib = "glyphicon"))
  }
}