if (!require(reshape2)) install.packages("reshape2")

# add Dataset factor
wals <- read.csv("../results/wals/results.csv")
wals$Dataset <- "WALS"
grambank <- read.csv("../results/grambank/results.csv")
grambank$Dataset <- "Grambank"

# rbind into a joint dataframe
data <- rbind(wals, grambank)

# change order of factor levels
data$Typology <- factor(data$okay, levels=c("interacting", "unknown", "non-interacting"))
data$Dataset <- factor(data$Dataset, levels=c("WALS", "Grambank"))

# add Delta_* columns for convenience
data$Delta_pref <- data$H_pref - data$H
data$Delta_dispref <- data$H_dispref - data$H

# construct a long format version
ldata = reshape2::melt(data, measure.vars=c("Delta_pref", "Delta_dispref"))

# writeout
save(data, ldata, file="../results/combined.RData")
