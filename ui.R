library(shiny)
library(markdown)
library(shinythemes)

#Function that defines our swiper functionality. 
#We call it a button because unless i'm mistaken it has to have some element to attach
#our input to. In this case a button that we hide(because we target the whole page.)
swiperButton <- function(inputId, value = "") {
  tagList(singleton(tags$head(
    tags$script(src = "touchSwipe.js"),
    tags$script(src = "shinySwiper.js"),
    tags$link(rel = "stylesheet", type = "text/css", href = "appStyle.css")
  )),
  tags$p(id = inputId,
         class = "swiper",
         "initializing"))
}


navbarPage(
  title = "papr",
  tabPanel(
    "Login",
    shinyjs::useShinyjs(),
    sidebarLayout(
      sidebarPanel(p("Welcome!"),
                   googleAuthR::googleAuthUI("gauth_login")),
      mainPanel(textOutput("display_username"))
    )
  ),
  tabPanel("Rate",
           sidebarLayout(
             sidebarPanel(
               h3("Rate the paper"),
               hr(),
               HTML(
                  "<table style='line-height:1.5em;'>
                    <tr>
                      <td style='font-weight:normal;'><i class = 'fa fa-arrow-right fa-2x' aria-hidden='true'></td>
                      <td style='font-weight:normal;'>Exciting and Correct
                        <i class = 'fa fa-star' aria-hidden='true'></i>
                      </td>
                    </tr>
                    <tr>
                      <td><i class = 'fa fa-arrow-up fa-2x' aria-hidden='true'></i></td>
                      <td>Exciting and Questionable
                        <i class = 'fa fa-volume-up' aria-hidden='true'></i>
                      </td>
                    </tr>
                    <tr>
                      <td><i class = 'fa fa-arrow-down fa-2x' aria-hidden='true'></td>
                      <td>Boring and Correct
                        <i class = 'fa fa-check' aria-hidden='true'></i>
                      </td>
                    </tr>
                    <tr>
                      <td><i class = 'fa fa-arrow-left fa-2x' aria-hidden='true'></i></td>
                      <td>Boring and Questionable
                        <i class = 'fa fa-trash' aria-hidden='true'></i>
                      </td>
                    </tr>
                  </table>"
               ),
               hr(),
               actionButton(
                 "skip",
                 "Unsure - skip paper",
                 icon = icon("question"),
                 width = '200px'
               ),
               h3(""),
               swiperButton("myswiper"), #Place our swiper button here, but again, we hide it.
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
               div(id = "swipeCard", 
                   h3(id = "cardTitle", "Title"),
                   hr(),
                   p(id = "cardAbstract", "Abstract content")
               )
             ))
             )),
  tabPanel("About",
           fluidPage(includeMarkdown("./about.md"))),
  tabPanel("Help",
           fluidPage(includeMarkdown("./help.md"))),
  collapsible = TRUE,
  windowTitle = "papr - peer review, but easier"
)
