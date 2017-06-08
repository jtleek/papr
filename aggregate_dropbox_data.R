library(rdrop2)
library(readr)
library(dplyr)
library(lubridate)
library(purrr)
library(tibble)

## -----------------------------------------------------------------
## pull all files
files <- drop_dir("shiny/2016/papr/", dtoken = token) %>%
  mutate(modified_ = as.POSIXct(modified, format="%a, %d %b %Y %H:%M:%S")) 
files_csv <- files %>%
  filter(grepl(".csv", path))
get_files <- function(path, date) {
  drop_read_csv(path, dtoken = token, stringsAsFactors = FALSE) %>%
    mutate(date = date,
           person = as.character(person))
}
a <- Sys.time()
files_tbl <- map2_df(files_csv$path, files_csv$modified, get_files)
b <- Sys.time()
b-a
file_path <- file.path(tempdir(), paste0(Sys.Date(), "_all-data.csv"))
write_csv(files_tbl, file_path)
drop_upload(file_path, "shiny/2016/papr/comb_dat", dtoken = token)
## -----------------------------------------------------------------
## update
files_md <- drop_dir("shiny/2016/papr/comb_dat/", dtoken = token) %>%
  mutate(modified = as.POSIXct(modified, format="%a, %d %b %Y %H:%M:%S"))

all_data_md <- files_md %>%
  filter(grepl("all-data", path)) %>%
  arrange(desc(modified))

all_data_path <- all_data_md %>%
  select(path) %>%
  slice(1) %>%
  as.character()
all_data_file <- drop_read_csv(all_data_path, dtoken = token, stringsAsFactors = FALSE) %>%
  mutate(date_ = as.POSIXct(date, format="%a, %d %b %Y %H:%M:%S")) 

last_session <- all_data_file %>%
  arrange(desc(date_)) %>%
  select(date_) %>%
  slice(1)

new_files_md <- files_csv %>% 
  filter(modified_ > last_session$date_)

new_files <- map2_df(new_files_md$path, new_files_md$modified, get_files)

old_data <- all_data_file %>%
  select(- date_)

all_data <- new_files %>%
  bind_rows(old_data)

file_path <- file.path(tempdir(), paste0(Sys.Date(), "_all-data.csv"))
write_csv(all_data, file_path)
drop_upload(file_path, "shiny/2016/papr/comb_dat", dtoken = token)
