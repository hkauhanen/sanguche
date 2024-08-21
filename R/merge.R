# read in both datasets
df1 <- read.csv("../results/wals/results_combined.csv")
df2 <- read.csv("../results/grambank/results_combined.csv")

# combine them
combined <- rbind(df1, df2)

# change order of factor levels
combined$status <- factor(combined$status, levels=c("interacting", "unknown", "non-interacting"))
combined$dataset <- factor(combined$dataset, levels=c("WALS", "Grambank"))

# construct a long format version
combined_long = reshape2::melt(combined, measure.vars=c("Delta_over", "Delta_under"))

# writeout
write.csv(combined, "../results/combined.csv", row.names=FALSE)
save(combined, combined_long, file="../results/combined.RData")

