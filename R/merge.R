df1 <- read.csv("../results/wals/results_combined.csv")
df2 <- read.csv("../results/grambank/results_combined.csv")

combined <- rbind(df1, df2)

combined$status <- factor(combined$status, levels=c("interacting", "unknown", "non-interacting"))

write.csv(combined, "../results/combined.csv", row.names=FALSE)

save(combined, file="../results/combined.RData")

