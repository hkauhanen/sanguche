require(ggplot2)
require(reshape2)
require(ggsci)

args <- commandArgs(trailingOnly=TRUE)
dataset <- args[1]

tryCatch(expr = {
         files <- list.files(path=paste0("../../", dataset, "/mrbayes/logs/"), pattern="*.csv", full.names=TRUE)

         read_one <- function(X) {
           df <- read.csv(X, header=FALSE)
           names(df) <- c("family", "timestamp", "generations", "ASDSF", "maxPSRF")
           df
         }

         df <- do.call(rbind, lapply(X=files, FUN=read_one))
         df$dataset <- "WALS"
         df$converged <- FALSE
         df$smaxPSRF = df$maxPSRF/240

         for (i in 1:nrow(df)) {
           famhere = df[i, ]$family
           if (file.exists(paste0("../../", dataset, "/mrbayes/converged/", famhere, ".txt"))) {
             df[i, ]$converged <- TRUE
           }
         }


         df$lty <- ifelse(df$converged, "1", "2")
         df$alpha <- ifelse(df$converged, 0.5, 1.0)


         df$converged <- ifelse(df$converged, "yes", "no")
         df$converged <- factor(df$converged, levels=c("no", "yes"))



         pdf(paste0("../../log/log_", dataset, ".pdf"), height=20, width=20)

         g_w <- ggplot(melt(df, measure.vars=c("ASDSF", "smaxPSRF")), aes(lty=variable, x=generations, y=value, color=converged, group=interaction(variable, family))) + geom_path(lwd=1.0, show.legend=TRUE) + facet_wrap(.~family, scales="free", nrow=10, ncol=9) + geom_hline(yintercept=0.005, lty=1, alpha=0.5, lwd=1.0) + theme_bw() + scale_color_npg() + theme(legend.position="top") + scale_y_log10() + annotation_logticks(sides="l")

         print(g_w)

         dev.off()
},
error = function(e) {
  print("nothing to do... no family has converged")
})

