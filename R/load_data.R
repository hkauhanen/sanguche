# load (and rename) dataframe "combined", which contains all our data
load("../results/combined.RData")
data <- combined
data <- data[data$pair != "PolQ & NegM", ]
data <- data[data$pair != "Gen & Pas", ]

# make "non-interacting" the reference level of "status" factor
data$status <- relevel(data$status, ref="non-interacting")

# neighbourhood sizes to use
k_wals <- round(sqrt(round(mean(data[data$dataset == "WALS", ]$N))))
k_grambank <- round(sqrt(round(mean(data[data$dataset == "Grambank", ]$N))))

print(k_wals)
print(k_grambank)

# restrict to final choice of k
wals <- data[data$dataset == "WALS" & data$k == k_wals, ]
gram <- data[data$dataset == "Grambank" & data$k == k_grambank, ]

data <- rbind(wals, gram)

# change order of factor levels
data$status <- factor(data$status, levels=c("interacting", "unknown", "non-interacting"))
data$dataset <- factor(data$dataset, levels=c("WALS", "Grambank"))
