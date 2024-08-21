require(tidyverse)
require(broom)
require(pixiedust)
require(emmeans)


# This loads a dataframe named "combined", which contains all our data
load("../results/combined.RData")



# Do k-against-k comparison, finding out how much lines of individual
# feature pairs "cross over" as k is increased. This is used to more
# objectively decide which k to use for which dataset. In practice,
# we take the Hamming distance between ordered vectors of pairs, ordered
# by increasing Delta_under.
kvsk <- function(data, dataset) {
  data <- data[data$dataset == dataset, ]
  k <- unique(data$k)
  status <- unique(data$status)
  diff <- rep(NA, length(k))

  out <- data.frame(k=k, dataset=dataset)

  for (st in status) {
  for (i in 1:(length(k) - 1)) {
    df1 <- data[data$status == st & data$k == k[i], ] %>% arrange(Delta_under)
    df2 <- data[data$status == st & data$k == k[i + 1], ] %>% arrange(Delta_under)
    out[out$k == k[i], st] <- nrow(df1) - sum(df1$pair == df2$pair)
  }
  }

  out$total <- rowSums(out[, c("unknown", "interacting", "non-interacting")])
  out
}

kvsk2 <- function(data, dataset) {
  data <- data[data$dataset == dataset, ]
  k <- unique(data$k)
  status <- unique(data$status)
  diff <- rep(NA, length(k))

  out <- data.frame(k=k, dataset=dataset)

  for (st in status) {
  for (i in 1:(length(k) - 1)) {
    df1 <- data[data$status == st & data$k == k[i], ]
    df2 <- data[data$status == st & data$k == k[i + 1], ]
    out[out$k == k[i], st] <- sum(abs(df1$Delta_under - df2$Delta_under))
  }
  }

  out$total <- rowSums(out[, c("unknown", "interacting", "non-interacting")])
  out
}

kvsk3 <- function(data, dataset) {
  data <- data[data$dataset == dataset, ]
  k <- unique(data$k)
  diff <- rep(NA, length(k))

  out <- data.frame(k=k, dataset=dataset)

  for (i in 1:(length(k) - 1)) {
    df1 <- data[data$k == k[i], ] %>% arrange(Delta_under)
    df2 <- data[data$k == k[i + 1], ] %>% arrange(Delta_under)
    out[out$k == k[i], "diff"] <- nrow(df1) - sum(df1$pair == df2$pair)
  }

  out
}


