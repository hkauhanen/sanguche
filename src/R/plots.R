# dependencies
require(tidyverse)
require(ggsci)
require(gridExtra)
require(reshape2)
require(ggplot2)
source("kloop.R")


# global resolution setting
glores <- 350


# create directory to save plots in
try(dir.create("../results/plots", recursive=TRUE))


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



# load data
source("load_data.R")





#####
# Main result (boxplot)
#####

data_onek_long <- melt(data, measure.vars=c("Delta_over", "Delta_under"))
levels(data_onek_long$variable) <- c("overattested", "underattested")

g <- ggplot(data_onek_long, aes(x=status, fill=status, y=value)) 
#g <- g + facet_grid(dataset~variable) 
g <- g + facet_wrap(.~dataset+variable, nrow=1)
g <- g + geom_boxplot(alpha=0.6)
g <- g + scale_fill_sanguche()
g <- g + deftheme()
g <- g + theme(axis.text.x=element_text(angle=40, hjust=1))
g <- g + theme(strip.text=element_text(size=10))
g <- g + xlab("")
g <- g + ylab(expression("Neighbourhood entropy differential"~Delta))
g <- g + theme(legend.position="none")#c(0.15, 0.89))

png("../results/plots/boxplot.png", res=glores, width=1800, height=1500)
print(g)
dev.off()



#####
# Mean distance to neighbour
#####

distances_wals <- read.csv("../tmp/wals/neighbour_distances.csv")
distances_gram <- read.csv("../tmp/grambank/neighbour_distances.csv")
distances_wals$dataset <- "WALS"
distances_gram$dataset <- "Grambank"

distances <- rbind(distances_wals, distances_gram)
distances$dataset <- factor(distances$dataset, levels=c("WALS", "Grambank"))

distances1 <- distances[distances$eachindex <= 1, ]
distances1$k <- 1
distances10 <- distances[distances$eachindex <= 10, ]
distances10$k <- 10
distances27 <- distances[distances$eachindex <= 27, ]
distances27$k <- 27
distances36 <- distances[distances$eachindex <= 36, ]
distances36$k <- 36
distances50 <- distances[distances$eachindex <= 50, ]
distances50$k <- 50
distances75 <- distances[distances$eachindex <= 75, ]
distances75$k <- 75

g <- ggplot(distances10[distances10$dataset == "WALS", ], aes(x=distance, fill=factor(k))) + geom_density(alpha=0.3)
g <- g + geom_density(data=distances1[distances1$dataset == "WALS", ], alpha=0.3)
g <- g + geom_density(data=distances27[distances27$dataset == "WALS", ], alpha=0.3)
g <- g + geom_density(data=distances50[distances50$dataset == "WALS", ], alpha=0.3)
#g <- g + geom_density(data=distances75[distances75$dataset == "WALS", ], alpha=0.3)
g <- g + scale_fill_sanguche2(name=expression(italic(k)))
g <- g + xlab("Distance to neighbour (km)") + ylab("Density")
g <- g + deftheme()
g <- g + scale_x_log10(limits=c(1, 10000))
g <- g + annotation_logticks(sides="b")
g <- g + theme(legend.position=c(0.08, 0.65))
g <- g + ggtitle("WALS")

g1 <- g

g <- ggplot(distances10[distances10$dataset == "Grambank", ], aes(x=distance, fill=factor(k))) + geom_density(alpha=0.3)
g <- g + geom_density(data=distances1[distances1$dataset == "Grambank", ], alpha=0.3)
g <- g + geom_density(data=distances36[distances36$dataset == "Grambank", ], alpha=0.3)
g <- g + geom_density(data=distances50[distances50$dataset == "Grambank", ], alpha=0.3)
#g <- g + geom_density(data=distances75[distances75$dataset == "Grambank", ], alpha=0.3)
g <- g + scale_fill_sanguche2(name=expression(italic(k)))
g <- g + xlab("Distance to neighbour (km)") + ylab("Density")
g <- g + deftheme()
g <- g + scale_x_log10(limits=c(1, 10000))
g <- g + annotation_logticks(sides="b")
g <- g + theme(legend.position=c(0.08, 0.65))
g <- g + ggtitle("Grambank")

g2 <- g


if (1 == 0) {
k_wals <- unique(wals$k)
k_grambank <- unique(gram$k)

wals_meanmean <- median(data[data$dataset == "WALS", ]$mean_distance)
grambank_meanmean <- median(data[data$dataset == "Grambank", ]$mean_distance)

meanmeans <- data.frame(dataset=c("WALS", "Grambank"), x=c(wals_meanmean, grambank_meanmean), k=c(k_wals, k_grambank))
meanmeans$pretty <- paste(round(meanmeans$x), "km")

g <- ggplot(data, aes(x=mean_distance, color=dataset, fill=dataset, lty=dataset))
g <- g + geom_density(position="identity", alpha=0.3) 
g <- g + deftheme() 
g <- g + theme(legend.position=c(0.84, 0.78))
g <- g + scale_fill_sanguche2() + scale_color_sanguche2()
g <- g + xlab("Mean distance to neighbour") 
g <- g + ylab("Density")
g <- g + guides(color=guide_legend("Dataset"), fill=guide_legend("Dataset"), lty=guide_legend("Dataset"))
g <- g + geom_vline(data=meanmeans, aes(xintercept=x, color=dataset, lty=dataset), alpha=0.9)
g <- g + geom_text(data=meanmeans, inherit.aes=FALSE, aes(x=x, y=0.0045, label=pretty), angle=90, nudge_x=-40, alpha=0.8, family="serif")
g <- g + xlim(0, 2000) + ylim(0, 0.005)
}

png("../results/plots/distances.png", res=glores, width=2000, height=2200)
g <- grid.arrange(g1, g2, nrow=2)
print(g)
dev.off()



#####
# p-values as function of k
#####

df1 <- kloop(fulldata, "WALS", "Delta_under", "status")
df1$Dataset <- "WALS"

df2 <- kloop(fulldata, "Grambank", "Delta_under", "status")
df2$Dataset <- "Grambank"

df <- rbind(df1, df2)
df$Dataset <- factor(df$Dataset, levels=c("WALS", "Grambank"))

g <- ggplot(df, aes(x=k, y=pval, pch=Dataset, color=Dataset))
g <- g + geom_line(alpha=0.9)
g <- g + geom_point(alpha=0.4, size=2.0)
#g <- g + geom_hline(yintercept=0.01, lty=2, alpha=0.8)
g <- g + geom_hline(yintercept=0.05, lty=2, alpha=0.8)
#g <- g + scale_y_log10(limits=c(0.001, 1))
g <- g + scale_y_log10(limits=c(0.02, 1))
g <- g + annotation_logticks(sides="l") 
g <- g + deftheme() 
#g <- g + theme(legend.position=c(0.38, 0.80))
g <- g + theme(legend.position="none")
#g <- g + annotate("text", x=90, y=0.012, parse=TRUE, label="italic(p)==0.01", size=3, alpha=0.9, family="serif")
g <- g + annotate("text", x=90, y=0.06, parse=TRUE, label="italic(p)==0.05", size=3, alpha=0.9, family="serif")
g <- g + scale_color_sanguche2()
g <- g + ylab(expression(italic(p)*"-value"))
g <- g + xlab(expression("Neighbourhood size"~italic(k)))

g1 <- g

g <- ggplot(df, aes(x=k, y=estimate, pch=Dataset, color=Dataset))
g <- g + geom_line(alpha=0.9)
g <- g + geom_point(alpha=0.4, size=2.0)
g <- g + deftheme() 
g <- g + theme(legend.position=c(0.72, 0.27))
g <- g + scale_color_sanguche2()
g <- g + ylab("Estimate")
g <- g + xlab(expression("Neighbourhood size"~italic(k)))
g <- g + ylim(-0.2, 0.2)

g2 <- g

g <- ggplot(df, aes(x=k, y=DAIC, pch=Dataset, color=Dataset))
g <- g + geom_line(alpha=0.9)
g <- g + geom_point(alpha=0.4, size=2.0)
g <- g + deftheme() 
g <- g + theme(legend.position=c(0.72, 0.27))
g <- g + scale_color_sanguche2()
g <- g + ylab(expression(Delta*"AIC in favour of"~phi[c]))
g <- g + xlab(expression("Neighbourhood size"~italic(k)))
#g <- g + ylim(-0.2, 0.2)

g3 <- g


png("../results/plots/ksweep_mod1_under.png", res=glores, width=2000, height=1200)
#png("../results/plots/ksweep_mod1_under.png", res=300, width=2000, height=2200)
plo <- grid.arrange(g2, g1, nrow=1)
#plo <- grid.arrange(plo, g3, nrow=2)
print(plo)
dev.off()


df1 <- kloop(fulldata, "WALS", "Delta_over", "status")
df1$Dataset <- "WALS"

df2 <- kloop(fulldata, "Grambank", "Delta_over", "status")
df2$Dataset <- "Grambank"

df <- rbind(df1, df2)
df$Dataset <- factor(df$Dataset, levels=c("WALS", "Grambank"))

g <- ggplot(df, aes(x=k, y=pval, pch=Dataset, color=Dataset))
g <- g + geom_line(alpha=0.9)
g <- g + geom_point(alpha=0.4, size=2.0)
#g <- g + geom_hline(yintercept=0.01, lty=2, alpha=0.8)
g <- g + geom_hline(yintercept=0.05, lty=2, alpha=0.8)
#g <- g + scale_y_log10(limits=c(0.001, 1))
g <- g + scale_y_log10(limits=c(0.02, 1))
g <- g + annotation_logticks(sides="l") 
g <- g + deftheme() 
#g <- g + theme(legend.position=c(0.38, 0.80))
g <- g + theme(legend.position="none")
#g <- g + annotate("text", x=15, y=0.008, parse=TRUE, label="italic(p)==0.01", size=3, alpha=0.9, family="serif")
g <- g + annotate("text", x=15, y=0.06, parse=TRUE, label="italic(p)==0.05", size=3, alpha=0.9, family="serif")
g <- g + scale_color_sanguche2()
g <- g + ylab(expression(italic(p)*"-value"))
g <- g + xlab(expression("Neighbourhood size"~italic(k)))

g1 <- g

g <- ggplot(df, aes(x=k, y=estimate, pch=Dataset, color=Dataset))
g <- g + geom_line(alpha=0.9)
g <- g + geom_point(alpha=0.4, size=2.0)
g <- g + deftheme() 
g <- g + theme(legend.position=c(0.72, 0.27))
g <- g + scale_color_sanguche2()
g <- g + ylab("Estimate")
g <- g + xlab(expression("Neighbourhood size"~italic(k)))
g <- g + ylim(-0.2, 0.2)

g2 <- g

g <- ggplot(df, aes(x=k, y=DAIC, pch=Dataset, color=Dataset))
g <- g + geom_line(alpha=0.9)
g <- g + geom_point(alpha=0.4, size=2.0)
g <- g + deftheme() 
g <- g + theme(legend.position=c(0.72, 0.27))
g <- g + scale_color_sanguche2()
g <- g + ylab(expression(Delta*"AIC in favour of"~phi[c]))
g <- g + xlab(expression("Neighbourhood size"~italic(k)))
#g <- g + ylim(-0.2, 0.2)

g3 <- g


png("../results/plots/ksweep_mod1_over.png", res=glores, width=2000, height=1200)
plo <- grid.arrange(g2, g1, nrow=1)
#plo <- grid.arrange(plo, g3, nrow=2)
print(plo)
dev.off()

