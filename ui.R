library(shiny)
library(markdown)
library(shinythemes)

swiperButton <- function(inputId, value = "") {
  tagList(
    singleton(tags$head(
      tags$script(src="touchSwipe.js"),
      tags$script(src="shinySwiper.js")
    )),
    tags$p(id = inputId,
           class = "swiper",
           "The last preprint was: ")
  )
}


navbarPage(title="papr",
           tabPanel("Rate",
                    sidebarLayout(
                      sidebarPanel(
                        h3("Swipe to rate the paper"),
                        hr(),
                        p(span(tagList(icon("arrow-right"), ": Exciting and Correct", icon("star")))),

                       # em(span(tagList(icon("star"),"Exciting and Correct"))),
                       p(span(tagList(icon("arrow-up"), ": Exciting and Questionable", icon("volume-up")))),
                       # em(span(tagList(icon("volume-up"),"Exciting and Questionable"))),
                       p(span(tagList(icon("arrow-down"), ": Boring and Correct", icon("check")))),

                      #  em(span(tagList(icon("ok",lib="glyphicon"),"Boring and Correct"))),
                      p(span(tagList(icon("arrow-left"), ": Boring and Questionable", icon("trash")))),
                        hr(),
                        actionButton("skip", "Unsure - skip paper",
                                     icon=icon("question"),width='200px'),
                        h3(""),
                        swiperButton("myswiper"),
                        hr(),
                        h3("Rate papers & level up:"),
                        uiOutput("icon"),
                        em(textOutput("level")),
                        h3("Download your ratings:"),
                        downloadButton("download_data", "Download"),
                        h3("Tell someone about papr:"),
                        a(href="https://twitter.com/intent/tweet?text=Check%20out%20papr%20its%20like%20Tinder%20for%20preprints%20https://jhubiostatistics.shinyapps.io/papr",icon("twitter")),
                        a(href="https://www.facebook.com/sharer/sharer.php?u=https%3A//jhubiostatistics.shinyapps.io/papr",icon("facebook"))
                      ),
                      mainPanel(
                        fluidPage(
                          div(id = "paper_info", #This id is used by the javascript as the area the swipes are registered.
                              div(id = "paper_text",
                                  h5(em("click and swipe abstract to rate"), align = "center"),
                                  hr(),
                                  h5("Title:\n"),
                                  p(textOutput("title")),
                                  h5("Authors:\n"),
                                  p(textOutput("authors")),
                                  h5("Abstract:\n"),
                                  em(textOutput("abstract")),
                                  h5("Link:\n"),
                                  uiOutput("link")
                              )
                          )
                        )
                      )
                    )
           ),
           tabPanel("About",
                    fluidPage(
                      includeMarkdown("./about.md")
                    )
           ),
           tabPanel("Help",
                    fluidPage(
                      includeMarkdown("./help.md")
                    )
           ),collapsible=TRUE, windowTitle = "papr - peer review, but easier"
)
