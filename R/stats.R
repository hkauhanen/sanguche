require(tidyverse)
require(broom)
require(pixiedust)
require(emmeans)


load("../results/combined.RData")

data10 = data[data$degree == 10, ]


try(dir.create("../results/tables", recursive=TRUE))


# preferred types, WALS
mod <- glm(Delta_pref~Typology, data10[data10$Dataset == "WALS", ], family=gaussian)
emm <- emmeans(mod, "Typology")
pem <- pairs(emm)
pem %>% tidy %>% select(-term) %>% select(-null.value) %>% dust %>% sprinkle(cols=c("estimate", "std.error", "statistic", "adj.p.value"), round=5) %>% sprinkle(cols="contrast", replace=c("interacting vs. non-interacting", "interacting vs. unknown", "unknown vs. non-interacting"))
write.csv(pem, file="../results/tables/pref_wals.csv", row.names=FALSE)


# dispreferred types, WALS
mod <- glm(Delta_dispref~Typology, data10[data10$Dataset == "WALS", ], family=gaussian)
emm <- emmeans(mod, "Typology")
pem <- pairs(emm)
pem %>% tidy %>% select(-term) %>% select(-null.value) %>% dust %>% sprinkle(cols=c("estimate", "std.error", "statistic", "adj.p.value"), round=5) %>% sprinkle(cols="contrast", replace=c("interacting vs. non-interacting", "interacting vs. unknown", "unknown vs. non-interacting"))
write.csv(pem, file="../results/tables/dispref_wals.csv", row.names=FALSE)




