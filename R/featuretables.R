source("load_data.R")

# add Delta statistics to featuretables (to go in the appendix)

ft1 <- read.csv("../results/featuretables/featuretable_wals.csv", header=FALSE)
names(ft1) <- c("pair", "N", "status", "LBF", "CPP", "phi", "phic")

ft2 <- read.csv("../results/featuretables/featuretable_grambank.csv")
names(ft2) <- c("pair", "N", "status", "LBF", "CPP", "phi", "phic")

ft1 <- merge(ft1, wals, by="pair")
ft1 <- ft1[, c("pair", "N.x", "status.x", "LBF.x", "CPP.x", "phi.x", "phic", "Delta_over", "Delta_under")]
ft1$Delta_over <- round(ft1$Delta_over, 3)
ft1$Delta_under <- round(ft1$Delta_under, 3)
ft1 <- ft1[order(ft1$LBF.x, decreasing=TRUE), ]

ft2 <- merge(ft2, gram, by="pair")
ft2 <- ft2[, c("pair", "N.x", "status.x", "LBF.x", "CPP.x", "phi.x", "phic", "Delta_over", "Delta_under")]
ft2$Delta_over <- round(ft2$Delta_over, 3)
ft2$Delta_under <- round(ft2$Delta_under, 3)
ft2 <- ft2[order(ft2$LBF.x, decreasing=TRUE), ]

write.table(ft1, file="../results/featuretables/featuretable_withDelta_wals.csv", row.names=FALSE, col.names=FALSE, sep=",", quote=FALSE)
write.table(ft2, file="../results/featuretables/featuretable_withDelta_grambank.csv", row.names=FALSE, col.names=FALSE, sep=",", quote=FALSE)
