library(tidyverse)
library(tidytext)
library(irlba)
library(quanteda)

data(stop_words)

load("./biorxiv_data.Rda") #R dataset of paper info
papers <- dat %>% 
  select(title, abstract)

word_counts <- papers %>% 
  unnest_tokens(word, abstract) %>% 
  count(title, word, sort = TRUE) %>% 
  ungroup()

word_freqs <- word_counts %>% 
  anti_join(stop_words) %>% 
  bind_tf_idf(word, title, n) 

term_mat <- word_freqs %>% 
  cast_dfm(title, word, tf) %>% 
  as.matrix()

# term_pca <- prcomp(term_mat,center = TRUE, scale. = TRUE) 

term_pca <- term_mat %*% irlba(term_mat, nv=5, nu=0, center=colMeans(term_mat), right_only=TRUE)$v

term_pca_df <- as_data_frame(term_pca) %>% 
  rename_(.dots = setNames(names(.), paste0("PC", 1:5))) %>% 
  mutate(title = rownames(term_pca), index = row_number())

save(term_pca_df,file = "./term_pca_df.Rda")
