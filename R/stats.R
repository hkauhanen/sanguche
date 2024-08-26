require(tidyverse)
require(broom)
require(pixiedust)
require(emmeans)


# This loads a dataframe named "combined", which contains all our data
load("../results/combined.RData")
data <- combined

try(dir.create("../results/tables", recursive=TRUE))


wals <- data[data$dataset == "WALS" & data$k == 8, ]
gram <- data[data$dataset == "Grambank" & data$k == 8, ]


mod_w <- glm(Delta_under ~ status+abs(phi), data=wals, family=gaussian)
mod_g <- glm(Delta_under ~ status+abs(phi), data=gram, family=gaussian)


print(summary(mod_w))
print(summary(mod_g))


mod_w <- glm(Delta_over ~ status+abs(phi), data=wals, family=gaussian)
mod_g <- glm(Delta_over ~ status+abs(phi), data=gram, family=gaussian)


print(summary(mod_w))
print(summary(mod_g))



if (1==0) {
# preferred types, WALS
mod <- glm(Delta_pref~Typology, data10[data10$Dataset == "WALS", ], family=gaussian)
emm <- emmeans(mod, "Typology")
pem <- pairs(emm)
out <- pem %>% tidy %>% select(-term) %>% select(-null.value) %>% dust %>% sprinkle(cols=c("estimate", "std.error", "statistic", "adj.p.value"), round=5)
write.csv(out, file="../results/tables/pref_wals.csv", row.names=FALSE)


# dispreferred types, WALS
mod <- glm(Delta_dispref~Typology, data10[data10$Dataset == "WALS", ], family=gaussian)
emm <- emmeans(mod, "Typology")
pem <- pairs(emm)
out <- pem %>% tidy %>% select(-term) %>% select(-null.value) %>% dust %>% sprinkle(cols=c("estimate", "std.error", "statistic", "adj.p.value"), round=5)
write.csv(out, file="../results/tables/dispref_wals.csv", row.names=FALSE)



# preferred types, Grambank
mod <- glm(Delta_pref~Typology, data10[data10$Dataset == "Grambank", ], family=gaussian)
emm <- emmeans(mod, "Typology")
pem <- pairs(emm)
out <- pem %>% tidy %>% select(-term) %>% select(-null.value) %>% dust %>% sprinkle(cols=c("estimate", "std.error", "statistic", "adj.p.value"), round=5)
write.csv(out, file="../results/tables/pref_grambank.csv", row.names=FALSE)


# dispreferred types, Grambank
mod <- glm(Delta_dispref~Typology, data10[data10$Dataset == "Grambank", ], family=gaussian)
emm <- emmeans(mod, "Typology")
pem <- pairs(emm)
out <- pem %>% tidy %>% select(-term) %>% select(-null.value) %>% dust %>% sprinkle(cols=c("estimate", "std.error", "statistic", "adj.p.value"), round=5)
write.csv(out, file="../results/tables/dispref_grambank.csv", row.names=FALSE)

}


