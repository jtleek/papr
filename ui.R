library(shiny)
library(markdown)
library(shinythemes)
library(plotly)

navbarPage(
  title = div(img(src="images/dark_logo_small.png", style="margin-top: -8px;", height = 40)),
  tabPanel(
    "Profile",
    fluidPage(
      shinyjs::useShinyjs(),
      div(id = "profile", class = "card",
          h3("Welcome to Papr"),
          em("Think of this as 'Tinder for pre-prints'. If you don't know what Tinder is, think of it as a web app for collecting gut-reactions to pre-prints from the scientific community. Enter your information below and click on the “Rate” tab to begin rating papers."),
          hr(),
          p(textOutput("display_username")),
          p( googleAuthR::googleAuthUI("gauth_login")),
          hr(),
          p("Consider entering your name & twitter handle so we can link you with other users"),
          textInput("name","Name"),
          textInput("twitter","Twitter handle"),
          hr()
      ) #end div
    ) #end fluidpage
  ),
  tabPanel("Rate",
           sidebarLayout(
             sidebarPanel(
               tags$head(
                 tags$script(src = "touchSwipe.js"),
                 tags$script(src = "shinySwiper.js"),
                 tags$link(rel = "stylesheet", type = "text/css", href = "appStyle.css")
               ),
               h3("Swipe abstract to rate the paper"),
               hr(),
               HTML(
                  "<table style='line-height:1.5em;'>
                    <tr>
                      <td style='font-weight:normal;'><img src = 'images/swipe_right.png', style='height: 40px'></td>
                      <td style='font-weight:normal;'> Exciting and Correct
                      </td>
                    </tr>
                    <tr>
                      <td><img src = 'images/swipe_up.png', style='height: 40px'></td>
                      <td> Exciting and Questionable
                      </td>
                    </tr>
                    <tr>
                      <td><img src = 'images/swipe_down.png', style='height: 40px'></td>
                      <td> Boring and Correct
                      </td>
                    </tr>
                    <tr>
                      <td><img src = 'images/swipe_left.png', style='height: 40px'></td>
                      <td> Boring and Questionable
                      </td>
                    </tr>
                  </table>"
               ),
               hr(),
               h3("Rate papers & level up:"),
               uiOutput("icon"),
               em(textOutput("level")),
               h3("Download your ratings:"),
               downloadButton("download_data", "Download"),
               h3("Tell someone about papr:"),
               a(href = "https://twitter.com/intent/tweet?text=Check%20out%20papr%20its%20like%20Tinder%20for%20preprints%20https://jhubiostatistics.shinyapps.io/papr", icon("twitter")),
               a(href = "https://www.facebook.com/sharer/sharer.php?u=https%3A//jhubiostatistics.shinyapps.io/papr", icon("facebook"))
               ),
             mainPanel(fluidPage(
               div(id = "swipeCard", class = "card",  
                   h3(id = "cardTitle", "Title"),
                   hr(),
                   p(id = "cardAbstract", "Abstract content")
               )
             ))
             )),
  tabPanel("What do I like?",
           fluidPage(
             div(id = "PCA_discussion", class = "card",
               h3("How we give you papers"),
                 hr(),
                 p("There are a lot of preprints out there. In an ideal world you could read them all, but you have things to do other than sit around an read abstracts all day."),
                 p(
                   span("In an attempt to help with this we have implemented what is known as a "),
                   a(href = "https://en.wikipedia.org/wiki/Recommender_system","recomender engine."),
                   span("What this allows us to do is tailor what abstracts we show you based upon your previous abstract rankings.")
                   ),
                 p(
                   span("In more technical terms what we do is take every abstract in our database and record how many times different words occur. We then take this very large dimensional data (each abstract has a column for every unique word we saw in all of the abstracts), and use a technique known as"),
                   a(href = "https://en.wikipedia.org/wiki/Principal_component_analysis", "Principle Components Analysis (PCA)"),
                   span("on it to attempt to simplify these thousands of words down to a few key patterns.")
                 ),
                 p(
                   span("Below is the raw data that we use to show you a given paper. Each blue dot represents one of the abstracts in our database plotted in the first three principle components. We start you at a random position in this cloud and when you like a paper we move your dot towards that given paper. The next abstract we select for you is then more likely to be drawn from the 'neighborhood' around your dot."),
                   span("Please explore! See if you can notice trends in the cloud of abstracts. Does your position make sense to you in the context of it's surroundings? The more abstracts you rate the better our estimates of your tastes will be!")
                 ),
               plotlyOutput("plotly")
             ) #end div
            ) #end fluidpage
          ),   #end tab
  tabPanel("Who's most like me?",
           fluidPage(
             div(class = "card static",  
                 h3("Most similar Papr users to you."),
                 hr(),
                 htmlOutput("friends"),
                 br(),
                 p("Using your past paper rankings, these are the users that have the most similar taste in preprints to you."),
                 p("Follow them, tweet at them, collaborate with them, write a new paper for people to rate on Papr!")
             )
            )
          ),
  tabPanel("About",
           fluidPage(
             div(id = "about", class = "card",  
                 includeMarkdown("./about.md")
             )
             )
           ),
  tabPanel("Help",
           fluidPage(
             div(class = "card",  
              includeMarkdown("./help.md")
              )
             )
           ),
  collapsible = TRUE,
  windowTitle = "papr - peer review, but easier"
)
