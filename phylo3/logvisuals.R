require(ggplot2)
require(reshape2)
require(ggsci)


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
wals$smaxPSRF = wals$maxPSRF/110

gram <- do.call(rbind, lapply(X=gram_files, FUN=read_one))
gram$dataset <- "Grambank"
gram$converged <- FALSE
gram$smaxPSRF = gram$maxPSRF/110


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


wals$lty <- ifelse(wals$converged, "1", "2")
wals$alpha <- ifelse(wals$converged, 0.5, 1.0)

gram$lty <- ifelse(gram$converged, "1", "2")
gram$alpha <- ifelse(gram$converged, 0.5, 1.0)


pdf("log.pdf", height=20, width=20)

g_w <- ggplot(melt(wals, measure.vars=c("ASDSF", "smaxPSRF")), aes(lty=variable, x=generations, y=value, color=converged, group=interaction(variable, family))) + geom_path(lwd=1.0) + facet_wrap(.~family, scales="free", nrow=9, ncol=9) + geom_hline(yintercept=0.01, lty=1, alpha=0.5, lwd=1.0) + ggtitle("WALS") + theme_bw() + scale_color_npg() + theme(legend.position="top") + scale_y_log10() + annotation_logticks(sides="l")

g_g <- ggplot(melt(gram, measure.vars=c("ASDSF", "smaxPSRF")), aes(lty=variable, x=generations, y=value, color=converged, group=interaction(variable, family))) + geom_path(lwd=1.0) + facet_wrap(.~family, scales="free", nrow=9, ncol=9) + geom_hline(yintercept=0.01, lty=1, alpha=0.5, lwd=1.0) + ggtitle("Grambank") + theme_bw() + scale_color_npg() + theme(legend.position="top") + scale_y_log10() + annotation_logticks(sides="l")

print(g_w)
print(g_g)

dev.off()
