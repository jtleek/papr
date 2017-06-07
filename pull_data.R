
## this is patched up from fulltext, as soon as that bug is fixed,
## we'll delete below & reinstall the regular one :)

########### PATCH TO DELETE AFTER fulltext BUG FIX ############# 
devtools::install_github("LucyMcgowan/fulltext")

############################################################# 
library("fulltext")
library("dplyr")

text <- biorxiv_search(query = "", limit = 12000)

col_author <- function(x) {
  paste(
    paste(x$given, x$family),
    collapse = ", "
  )
}


dat_new <- text$data %>%
  select(title, url = URL, issued, author, abstract) %>%
  mutate(authors = purrr::map_chr(author, col_author),
         abstract = gsub("<jats:.*?>|</jats:.*?>", "", abstract),
         issued = as.Date(issued)) %>%
  select(-author) %>%
  distinct(title, .keep_all = TRUE)

save(dat_new, file = "./biorxiv_data_new.Rda")

load("./biorxiv_data_old.Rda")
dat <- dat %>%
  select(title = titles,
         url = links,
         issued = posted,
         authors,
         abstract = abstracts) %>%
  bind_rows(dat_new) %>%
  distinct(title, .keep_all = TRUE) %>%
  mutate(index = 1:n())


save(dat, file = "biorxiv_data.Rda")


