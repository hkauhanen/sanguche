require(tidyverse)
require(broom)
require(pixiedust)
require(emmeans)

source("kvsk.R")


try(dir.create("../results/tables", recursive=TRUE))


# This loads a dataframe named "combined", which contains all our data
load("../results/combined.RData")
data <- combined
data <- data[data$pair != "PolQ & NegM", ]


# Make "non-interacting" the reference level of "status" factor
data$status <- relevel(data$status, ref="non-interacting")


# Inflection points
wals_mean_inflpoint <- round(mean_inflection_point(data, "WALS"))
gram_mean_inflpoint <- round(mean_inflection_point(data, "Grambank"))
wals_max_inflpoint <- max_inflection_point(data, "WALS")
gram_max_inflpoint <- max_inflection_point(data, "Grambank")

ipdf <- data.frame(dataset=c("WALS", "Grambank"), mean_inflpoint=c(wals_mean_inflpoint, gram_mean_inflpoint), max_inflpoint=c(wals_max_inflpoint, gram_max_inflpoint))

write.csv(ipdf, file="../results/tables/inflection_points.csv", row.names=FALSE)


# Restrict to final choice of k
wals <- data[data$dataset == "WALS" & data$k == wals_max_inflpoint, ]
gram <- data[data$dataset == "Grambank" & data$k == gram_max_inflpoint, ]


# Basic model: comparison of Delta_under between different statuses
mod_w <- glm(Delta_under ~ status+abs(phi), data=wals, family=gaussian)
mod_g <- glm(Delta_under ~ status+abs(phi), data=gram, family=gaussian)

mod_w %>% dust %>% sprinkle(round=5) %>% write.csv(file="../results/tables/mod1_under_wals.csv", row.names=FALSE)
mod_g %>% dust %>% sprinkle(round=5) %>% write.csv(file="../results/tables/mod1_under_grambank.csv", row.names=FALSE)


# Basic model: comparison of Delta_over between different statuses
mod_w <- glm(Delta_over ~ status+abs(phi), data=wals, family=gaussian)
mod_g <- glm(Delta_over ~ status+abs(phi), data=gram, family=gaussian)

mod_w %>% dust %>% sprinkle(round=5) %>% write.csv(file="../results/tables/mod1_over_wals.csv", row.names=FALSE)
mod_g %>% dust %>% sprinkle(round=5) %>% write.csv(file="../results/tables/mod1_over_grambank.csv", row.names=FALSE)


# Model 2: regress Delta on phi_c; underrepresented
mod_w <- glm(Delta_under ~ abs(corrected_phi)+abs(phi), data=wals, family=gaussian)
mod_g <- glm(Delta_under ~ abs(corrected_phi)+abs(phi), data=gram, family=gaussian)

mod_w %>% dust %>% sprinkle(round=5) %>% write.csv(file="../results/tables/mod2_under_wals.csv", row.names=FALSE)
mod_g %>% dust %>% sprinkle(round=5) %>% write.csv(file="../results/tables/mod2_under_grambank.csv", row.names=FALSE)



# Model 2: regress Delta on phi_c; overrepresented
mod_w <- glm(Delta_over ~ abs(corrected_phi)+abs(phi), data=wals, family=gaussian)
mod_g <- glm(Delta_over ~ abs(corrected_phi)+abs(phi), data=gram, family=gaussian)

mod_w %>% dust %>% sprinkle(round=5) %>% write.csv(file="../results/tables/mod2_over_wals.csv", row.names=FALSE)
mod_g %>% dust %>% sprinkle(round=5) %>% write.csv(file="../results/tables/mod2_over_grambank.csv", row.names=FALSE)



