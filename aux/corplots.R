require(ggplot2)
require(ggrepel)
require(gridExtra)


prep_dataframe <- function(filename,
                           variable = "feature.pair",
                           sep = "-") {
  data <- read.csv(filename)
  data$f1 <- do.call(rbind, strsplit(data[[variable]], sep))[, 1]
  data$f2 <- do.call(rbind, strsplit(data[[variable]], sep))[, 2]

  data$pair <- NA
  for (i in 1:nrow(data)) {
    sorted <- sort(c(data[i, ]$f1, data[i, ]$f2))
    data[i, ]$pair <- paste(sorted[1], "&", sorted[2])
  }

  data
}

wals <- prep_dataframe("aux/wals_results_combined.csv", variable="pair", sep=" & ")
wals <- wals[wals$k == min(wals$k), ]

gram <- prep_dataframe("results/grambank/sand_results.csv", variable="pair", sep=" & ")
gram <- gram[gram$degree == min(gram$degree), ]

both <- merge(wals, gram, by="pair")

g1 <- ggplot(both, aes(x=phi.x, y=phi.y)) + xlim(0,1) + ylim(0,1) + geom_abline(slope=1, lty=2) + xlab("WALS") + ylab("Grambank") + ggtitle("(A) Plain phi coefficient") + geom_smooth(method=lm) + geom_text_repel(aes(label=pair), alpha=0.85, box.padding=0.95) + geom_point(size=2.0)

wals <- prep_dataframe("aux/wals_correlations.csv")
gram <- prep_dataframe("results/grambank/correlations.csv")
both <- merge(wals, gram, by="pair")

g2 <- ggplot(both, aes(x=median.x, y=median.y)) + xlim(0,1) + ylim(0,1) + geom_abline(slope=1, lty=2) + xlab("WALS") + ylab("Grambank") + ggtitle("(B) Median of posterior distribution of phi") + geom_smooth(method=lm) + geom_text_repel(aes(label=pair), alpha=0.85, box.padding=0.95) + geom_point(size=2.0)


pdf("aux/corplots.pdf", height=12, width=7)
print(grid.arrange(g1, g2, nrow=2))
dev.off()
