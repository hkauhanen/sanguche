require(ggplot2)


wals_files <- list.files(path="wals/code/mrbayes/logs/", pattern="*.csv", full.names=TRUE)
gram_files <- list.files(path="grambank/code/mrbayes/logs/", pattern="*.csv", full.names=TRUE)

read_one <- function(X) {
  df <- read.csv(X, header=FALSE)
  names(df) <- c("family", "timestamp", "generations", "ASDSF", "maxPSRF")
  df
}

wals <- do.call(rbind, lapply(X=wals_files, FUN=read_one))
wals$dataset <- "WALS"
wals$converged <- FALSE

gram <- do.call(rbind, lapply(X=gram_files, FUN=read_one))
gram$dataset <- "Grambank"
gram$converged <- FALSE

for (i in 1:nrow(wals)) {
  famhere = wals[i, ]$family
  if (file.exists(paste0("wals/code/mrbayes/converged/", famhere, ".txt"))) {
    wals[i, ]$converged <- TRUE
  }
}

for (i in 1:nrow(gram)) {
  famhere = gram[i, ]$family
  if (file.exists(paste0("grambank/code/mrbayes/converged/", famhere, ".txt"))) {
    gram[i, ]$converged <- TRUE
  }
}


logs <- rbind(wals, gram)



pdf("log.pdf", height=10, width=10)

g_w1 <- ggplot(wals, aes(x=generations, y=ASDSF, color=converged, group=family)) + geom_path() + facet_wrap(.~family, scales="free") + geom_hline(yintercept=0.01, lty=2) + ggtitle("WALS, ASDSF")

g_g1 <- ggplot(gram, aes(x=generations, y=ASDSF, color=converged, group=family)) + geom_path() + facet_wrap(.~family, scales="free") + geom_hline(yintercept=0.01, lty=2) + ggtitle("Grambank, ASDSF")

g_w2 <- ggplot(wals, aes(x=generations, y=maxPSRF, color=converged, group=family)) + geom_path() + facet_wrap(.~family, scales="free") + geom_hline(yintercept=1.1, lty=2) + ggtitle("WALS, maxPSRF")

g_g2 <- ggplot(gram, aes(x=generations, y=maxPSRF, color=converged, group=family)) + geom_path() + facet_wrap(.~family, scales="free") + geom_hline(yintercept=1.1, lty=2) + ggtitle("Grambank, maxPSRF")

print(g_w1)
print(g_w2)
print(g_g1)
print(g_g2)

dev.off()
