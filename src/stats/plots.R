dataset <- commandArgs(trailingOnly=TRUE)[1]
limtype <- commandArgs(trailingOnly=TRUE)[2]

require(tidyverse)
require(ggrepel)
require(ggsci)
require(gridExtra)

source("kloop.R")


dir.create("../../results/plots")
dir.create(paste0("../../results/plots/", dataset))


# default theme
deftheme <- function() {
  g <- theme_bw()
  #  g <- g + theme(panel.grid.major=element_blank(), panel.grid.minor=element_blank())
  g <- g + theme(panel.grid.minor=element_blank())
  g <- g + theme(axis.text=element_text(color="black"))
  g <- g + theme(strip.text=element_text(size=12), strip.background=element_blank())
  #g <- g + theme(strip.text=element_text(size=12, hjust=0), strip.background=element_blank())
  g <- g + theme(text=element_text(family="serif"))
  g
}


# default colour palettes
mypal <- pal_aaas(alpha=1.0)(5)
mypal <- mypal[c(3,1,2, 5:4)]
mypal2 <- mypal[c(5,4,3,1,2)]

scale_color_sanguche <- function(...) {
  scale_color_manual(values=mypal, ...)
}

scale_color_sanguche2 <- function(...) {
  scale_color_manual(values=mypal2, ...)
}

scale_fill_sanguche <- function(...) {
  scale_fill_manual(values=mypal, ...)
}

scale_fill_sanguche2 <- function(...) {
  scale_fill_manual(values=mypal2, ...)
}




data <- read.csv(paste0("../../results/", dataset, "/results_combined.csv"), na.strings="missing")
data$k <- data$degree

#data_onek <- data[data$k == 850, ]
data_onek <- data[data$k == 500, ]


data_onek$Typology <- factor(data_onek$status, levels=c("interacting", "unknown", "non-interacting"))



g <- ggplot(data_onek, aes(x=Typology, fill=Typology, y=Delta_under))
g <- g + geom_boxplot(alpha=0.5)
g <- g + geom_jitter()
g <- g + deftheme()
g <- g + scale_fill_sanguche2()
g <- g + theme(legend.position="none")
g <- g + ylab(expression("Neighbourhood entropy"~Delta^"-"))
g <- g + ggtitle("(a)")
g1 <- g

g <- ggplot(data_onek, aes(x=Typology, fill=Typology, y=Delta_over))
g <- g + geom_boxplot(alpha=0.5)
g <- g + geom_jitter()
g <- g + deftheme()
g <- g + scale_fill_sanguche2()
g <- g + theme(legend.position="none")
g <- g + ylab(expression("Neighbourhood entropy"~Delta^"+"))
g <- g + ggtitle("(b)")
g2 <- g

png("../../results/plots/boxplot.png", res=400, height=1500, width=2700)
print(grid.arrange(g1, g2, nrow=1))
dev.off()




g <- ggplot(data[data$k <= 2000, ], aes(x=k, group=k, y=round(mean_nsize))) + geom_boxplot(fill=mypal[2], alpha=0.5, outlier.shape=NA) + deftheme() + xlab(expression("Neighbourhood radius limit"~italic(R))) + ylab("Mean number of neighbours") + geom_hline(yintercept=27, lty=2)

png("../../results/plots/neighbourhoods.png", res=450, height=2200, width=2700)
print(g)
dev.off()




g <- ggplot(data_onek, aes(x=abs(corrected_phi), y=Delta_under, pch=Typology, color=Typology)) 
g <- g + geom_smooth(inherit.aes=FALSE, aes(x=abs(corrected_phi), y=Delta_under), method=lm, color="black")
g <- g + geom_point(size=2.5)
#g <- g + geom_text_repel(aes(label=pair), family="serif") 
g <- g + deftheme() 
g <- g + scale_color_sanguche2()
g <- g + xlab(expression("Corrected correlation"~abs(phi[c])))
g <- g + ylab(expression("Neighbourhood entropy differential"~Delta^"-"))


png("../../results/plots/Delta_phic.png", res=450, height=2000, width=2700)
print(g)
dev.off()





#### sweeps

if (limtype == "rank") {
  xaxistitle <- expression("Neighbourhood size"~italic(k))
} else {
  xaxistitle <- expression("Neighbourhood radius limit"~italic(R))
}

kl1 <- kloop(data, unique(data$dataset), var="Delta_under", klim=4000)
kl1$predictor <- "categorical"

#kl2 <- kloop(data, unique(data$dataset), variable="Delta_under", indvariable="abs_corrected_phi", klim=10000)
#kl2$predictor <- "continuous"

#kl <- rbind(kl1, kl2)
kl <- kl1

g1 <- ggplot(kl, aes(x=k, y=estimate, pch=predictor, color=predictor)) 
#g1 <- g1 + geom_point() 
g1 <- g1 + geom_line()
g1 <- g1 + deftheme()
g1 <- g1 + scale_color_sanguche()
g1 <- g1 + theme(legend.position=c(0.7, 0.82))
g1 <- g1 + xlab(xaxistitle)
g1 <- g1 + ylab("Estimate")
g1 <- g1 + ggtitle("(a)")

g0 <- g1

g1 <- ggplot(kl, aes(x=k, y=effect.size, pch=predictor, color=predictor)) 
#g1 <- g1 + geom_point() 
g1 <- g1 + geom_line()
g1 <- g1 + deftheme()
g1 <- g1 + scale_color_sanguche()
g1 <- g1 + theme(legend.position="none")
g1 <- g1 + xlab(xaxistitle)
g1 <- g1 + ylab("Effect size")
g1 <- g1 + ggtitle("Delta-difference for UNDERrepresented types")

g2 <- ggplot(kl, aes(x=k, y=pvalue, pch=predictor, color=predictor)) 
#g1 <- g1 + geom_point() 
g2 <- g2 + geom_line()
g2 <- g2 + deftheme()
g2 <- g2 + scale_color_sanguche()
g2 <- g2 + theme(legend.position="none")
g2 <- g2 + xlab(xaxistitle)
g2 <- g2 + ylab(expression(italic(p)*"-value"))
g2 <- g2 + scale_y_log10() + annotation_logticks(sides="l")
g2 <- g2 + geom_hline(yintercept=0.01, lty=2)
#g2 <- g2 + annotate("text", x=1850, y=0.006, label=expression(italic(p)==0.01), family="serif", parse=TRUE)
#g2 <- g2 + ggtitle("(b) p-value")


png(paste0("../../results/plots/", dataset, "/kloop_under.png"), res=400, height=2700, width=2700)
print(grid.arrange(g1, g2, nrow=2))
dev.off()




kl1 <- kloop(data, unique(data$dataset), var="Delta_over", klim=4000)
kl1$predictor <- "categorical"

#kl2 <- kloop(data, unique(data$dataset), variable="Delta_over", indvariable="abs_corrected_phi", klim=10000)
#kl2$predictor <- "continuous"

#kl <- rbind(kl1, kl2)
kl <- kl1

g1 <- ggplot(kl, aes(x=k, y=estimate, pch=predictor, color=predictor)) 
#g1 <- g1 + geom_point() 
g1 <- g1 + geom_line()
g1 <- g1 + deftheme()
g1 <- g1 + scale_color_sanguche()
g1 <- g1 + theme(legend.position="none")
g1 <- g1 + xlab(xaxistitle)
g1 <- g1 + ylab("Estimate")
g1 <- g1 + ggtitle("(a)")

g0 <- g1

g1 <- ggplot(kl, aes(x=k, y=effect.size, pch=predictor, color=predictor)) 
#g1 <- g1 + geom_point() 
g1 <- g1 + geom_line()
g1 <- g1 + deftheme()
g1 <- g1 + scale_color_sanguche()
g1 <- g1 + theme(legend.position="none")
g1 <- g1 + xlab(xaxistitle)
g1 <- g1 + ylab("Effect size")
g1 <- g1 + ggtitle("Delta-difference for OVERrepresented types")

g2 <- ggplot(kl, aes(x=k, y=pvalue, pch=predictor, color=predictor)) 
#g1 <- g1 + geom_point() 
g2 <- g2 + geom_line()
g2 <- g2 + deftheme()
g2 <- g2 + scale_color_sanguche()
g2 <- g2 + theme(legend.position="none")
g2 <- g2 + xlab(xaxistitle)
g2 <- g2 + ylab(expression(italic(p)*"-value"))
g2 <- g2 + scale_y_log10() + annotation_logticks(sides="l")
g2 <- g2 + geom_hline(yintercept=0.01, lty=2)
#g2 <- g2 + annotate("text", x=1850, y=0.007, label=expression(italic(p)==0.01), family="serif", parse=TRUE)
#g2 <- g2 + ggtitle("(b) p-value")


png(paste0("../../results/plots/", dataset, "/kloop_over.png"), res=400, height=2700, width=2700)
print(grid.arrange(g1, g2, nrow=2))
dev.off()



