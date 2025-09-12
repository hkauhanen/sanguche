# required packages
require(tidyverse)
require(reshape2)
require(broom)
require(pixiedust)
require(emmeans)
require(stringr)
require(ggplot2)
require(gridExtra)
require(ggsci)
source("pvalString_demo.R")
source("kloop.R")

prep_data <- function(dataset) {
	# load data
	data <- read.csv(paste0("../../results/", dataset, "/results_combined.csv"))

	# rename "non-interacting" as "control"
	data$status <- ifelse(data$status == "non-interacting", "control", data$status)
	data$status <- factor(data$status)
	data$status <- relevel(data$status, ref="control")

	# return
	data
} 

wals <- prep_data("wals")
gram <- prep_data("grambank")

fullwals <- wals
fullgram <- gram

wals <- wals %>% group_by(pair) %>% filter(degree == round(sqrt(N)))
gram <- gram %>% group_by(pair) %>% filter(degree == round(sqrt(N)))

gram_smol <- prep_data("grambank")
kless <- -30
gram_smol <- gram_smol %>% group_by(pair) %>% filter(degree == round(sqrt(N)) + kless)



# plots

wals$dataset <- "WALS"
gram$dataset <- "Grambank"
gram_smol$dataset <- "Grambank SN"

all <- rbind(wals, gram, gram_smol)


boxyplot <- function(data, 
                     exclude = NULL,
                     ylim = c(-0.06, 0.11)) {
  data[data$dataset %in% exclude, ]$Delta_under <- NA
  data[data$dataset %in% exclude, ]$Delta_over <- NA

  g1 <- ggplot(data, aes(x=dataset, y=Delta_under, fill=status)) + geom_boxplot(outlier.shape=NA) + ggtitle("Underrepresented types") + xlab("Dataset") + ylab("Neighbourhood entropy differential") + scale_fill_npg(name="Typology", guide="none") + ylim(ylim)
  g2 <- ggplot(data, aes(x=dataset, y=Delta_over, fill=status)) + geom_boxplot(outlier.shape=NA) + ggtitle("Overrepresented types") + xlab("Dataset") + ylab("Neighbourhood entropy differential") + scale_fill_npg(name="Typology") + ylim(ylim)

  grid.arrange(g1, g2, nrow=1, widths=c(0.8, 1.0))
}


wi <- 3000
he <- 1600
dpi <- 350

boxyplot(all, exclude=c("Grambank", "Grambank SN"), ylim=c(-0.025, 0.075)) %>% ggsave(filename="../../results/plots/compila2025/boxplot_WALS.png", device="png", units="px", width=wi, height=he, dpi=dpi)
boxyplot(all, exclude=c("Grambank SN"), ylim=c(-0.025, 0.075)) %>% ggsave(filename="../../results/plots/compila2025/boxplot_WALS_Grambank.png", device="png", units="px", width=wi, height=he, dpi=dpi)
boxyplot(all, exclude=NULL, ylim=c(-0.075, 0.15)) %>% ggsave(filename="../../results/plots/compila2025/boxplot_all.png", device="png", units="px", width=wi, height=he, dpi=dpi)




klo_wals <- kloop(fullwals, "underattested", ks=-23:110)
klo_gram <- kloop(fullgram, "underattested", ks=-39:40)

klo_wals$dataset <- "WALS"
klo_gram$dataset <- "Grambank"

klo <- rbind(klo_wals, klo_gram)

klo <- klo[, c("k", "dataset", "effect.size", "pvalue")]
names(klo) <- c("l", "database", "effect size", "p-value")


klo <- melt(klo, id.vars=c("l", "database"))

g <- ggplot(klo, aes(x=l, y=value)) + geom_line() + facet_grid(variable~database, scales="free") + xlab("Nudge to neighbourhood size, ℓ") + ylab("") + ggtitle("Contrast: interacting vs. control")
#g1 <- ggplot(klo, aes(x=k, y=effect.size)) + geom_line() + facet_wrap(.~dataset, scales="free") + scale_y_continuous(limits=c(-2.5, 0.5))
#g2 <- ggplot(klo, aes(x=k, y=pvalue)) + geom_line() + facet_wrap(.~dataset, scales="free") + scale_y_log10(limits=c(1e-07, 1.0))

#g <- grid.arrange(g1, g2, nrow=2)
g
ggsave(filename="../../results/plots/compila2025/ksweep.png", plot=g, device="png", units="px", width=3000, height=2000, dpi=500)

