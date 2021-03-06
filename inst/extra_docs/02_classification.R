## Load Packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(termco, qdapRegex, stringi, dplyr, ggplot2, readr)


## Read in Data
dat <- readr::read_csv("data/")

## Split Data Into Training & Test Sets
set.seed(111)
(split_dat <- split_data(dat, .5))
train <- split_dat$train
testing <- split_dat$test

## Inspect Data

n <- 50
train %>%
    with(frequent_terms(dialogue, n = n))

train %>%
    with(frequent_terms(dialogue, n = n)) %>%
    plot()

train %>%
    with(frequent_terms(dialogue, n = n)) %>%
    plot(as.cloud=TRUE)

# Ngram Colocations
train %>%
    with(ngram_collocations(dialogue)) %>%
    plot()

## Build the Model
file.edit("categories/categories.R")
cats <- source("categories/categories.R")[["value"]]

model <- train %>%
    with(term_count(dialogue, grouping.var = TRUE, cats))

## Testing the Model
model %>%
    coverage()

# Discrimination
model %>%
    as_terms() %>%
    plot_freq(size=3) + xlab("Number of Tags")

# Category Loadings
model %>%
    as_terms() %>%
    plot_counts() + xlab("Tags")


## Improving the Model
untagged <- get_uncovered(model)


untagged %>%
    frequent_terms()

# Terms That Colocate with a Frequent Term
untagged %>%
    search_term("termA") %>%
    frequent_terms(10, stopwords = "TooFrequentTerm")


# Colocation Regex
# options(termco.copy2clip = TRUE) ## copies colo output to clipboard
colo("\\btermA", "(termB|termC)")


## Classification
classify(model) %>% plot()



## Coverage on Testing Data
testing %>%
    with(term_count(dialogue, grouping.var = TRUE, cats)) %>%
    coverage()

