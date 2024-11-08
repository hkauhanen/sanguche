# dependencies
require(tidyverse)
require(ggsci)
require(gridExtra)
require(reshape2)
require(ggplot2)
source("kloop.R")


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
  g
}


# default colour palettes
mypal <- pal_aaas(alpha=1.0)(5)
mypal <- mypal[c(3,1,2, 5:4)]
mypal2 <- mypal[c(5,4,3,1,2)]

scale_color_sanguche <- function() {
  scale_color_manual(values=mypal)
}

scale_color_sanguche2 <- function() {
  scale_color_manual(values=mypal2)
}

scale_fill_sanguche <- function() {
  scale_fill_manual(values=mypal)
}

scale_fill_sanguche2 <- function() {
  scale_fill_manual(values=mypal2)
}



# load data
source("load_data.R")




##### 
# Delta_under as a function of neighbourhood size k
#####

g <- ggplot(fulldata[fulldata$k %in% round(exp(seq(from=log(1), to=log(100), length.out=20))), ], aes(x=k, y=Delta_under, color=status, group=pair)) 
g <- g + geom_point(alpha=0.5) + geom_line(alpha=0.5) 
g <- g + scale_x_log10() 
g <- g + facet_grid(status~dataset) 
#g <- g + geom_ribbon(data=data_d, inherit.aes=FALSE, aes(fill=status, x=k, ymin=q, ymax=Q), alpha=0.10) 
#g <- g + geom_path(data=data_d, inherit.aes=FALSE, aes(color=status, x=k, y=mean), lwd=2.0) 
g <- g + annotation_logticks(sides="b")
g <- g + scale_color_sanguche() + scale_fill_sanguche()
g <- g + xlab(expression("Neighbourhood size"~italic(k)))
g <- g + ylab(expression("Neighbourhood entropy differential"~Delta^~{"–"}))
g <- g + deftheme() 
g <- g + theme(legend.position="none")
png("../results/plots/neighbourhood_dispref.png", res=300, width=1800, height=2500)
print(g)
dev.off()


#####
# Main result (boxplot)
#####

data_onek_long <- melt(data, measure.vars=c("Delta_over", "Delta_under"))
levels(data_onek_long$variable) <- c("over-represented", "under-represented")

g <- ggplot(data_onek_long, aes(x=status, fill=status, y=value)) 
#g <- g + facet_grid(dataset~variable) 
g <- g + facet_wrap(.~dataset+variable, nrow=1)
g <- g + geom_boxplot(alpha=0.8)
g <- g + scale_fill_sanguche()
g <- g + deftheme()
g <- g + theme(axis.text.x=element_text(angle=40, hjust=1))
g <- g + theme(strip.text=element_text(size=10))
g <- g + xlab("")
g <- g + ylab(expression("Neighbourhood entropy differential"~Delta))
g <- g + theme(legend.position="none")#c(0.15, 0.89))

png("../results/plots/boxplot.png", res=300, width=1800, height=1500)
print(g)
dev.off()



#####
# Mean distance to neighbour
#####

wals_meanmean <- median(data[data$dataset == "WALS", ]$mean_distance)
grambank_meanmean <- median(data[data$dataset == "Grambank", ]$mean_distance)
meanmeans <- data.frame(dataset=c("WALS", "Grambank"), x=c(wals_meanmean, grambank_meanmean), k=c(ip_wals, ip_grambank))
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
g <- g + geom_text(data=meanmeans, inherit.aes=FALSE, aes(x=x, y=0.0045, label=pretty), angle=90, nudge_x=-40, alpha=0.8)
g <- g + xlim(0, 2000) + ylim(0, 0.005)


png("../results/plots/distances.png", res=300, width=2000, height=1500)
print(g)
dev.off()


#####
# p-values as function of k
#####

df1 <- kloop(fulldata, data, "WALS", "Delta_under", "status")
df1$Dataset <- "WALS"

df2 <- kloop(fulldata, data, "Grambank", "Delta_under", "status")
df2$Dataset <- "Grambank"

df <- rbind(df1, df2)
df$Dataset <- factor(df$Dataset, levels=c("WALS", "Grambank"))

g <- ggplot(df, aes(x=k, y=pval, pch=Dataset, color=Dataset))
g <- g + geom_line(alpha=0.6)
g <- g + geom_point(alpha=0.9, size=2.0)
g <- g + geom_hline(yintercept=0.01, lty=2, alpha=0.8)
g <- g + geom_hline(yintercept=0.05, lty=2, alpha=0.8)
g <- g + scale_y_log10(limits=c(0.0001, 1))
g <- g + annotation_logticks(sides="l") 
g <- g + deftheme() 
#g <- g + theme(legend.position=c(0.38, 0.80))
g <- g + theme(legend.position="none")
g <- g + annotate("text", x=-7.5, y=0.0070, parse=TRUE, label="italic(p)==0.01", size=3, alpha=0.9)
g <- g + annotate("text", x=-7.5, y=0.035, parse=TRUE, label="italic(p)==0.05", size=3, alpha=0.9)
g <- g + scale_color_sanguche2()
g <- g + ylab(expression(italic(p)*"-value"))
g <- g + xlab(expression("Neighbourhood size relative to optimal"))

g1 <- g

g <- ggplot(df, aes(x=k, y=estimate, pch=Dataset, color=Dataset))
g <- g + geom_line(alpha=0.6)
g <- g + geom_point(alpha=0.9, size=2.0)
g <- g + deftheme() 
g <- g + theme(legend.position=c(0.72, 0.27))
g <- g + scale_color_sanguche2()
g <- g + ylab("Estimate")
g <- g + xlab(expression("Neighbourhood size relative to optimal"))
g <- g + ylim(-0.2, 0.2)

g2 <- g

png("../results/plots/ksweep_mod1_under.png", res=300, width=2000, height=1200)
print(grid.arrange(g2, g1, nrow=1))
dev.off()


df1 <- kloop(fulldata, data, "WALS", "Delta_over", "status")
df1$Dataset <- "WALS"

df2 <- kloop(fulldata, data, "Grambank", "Delta_over", "status")
df2$Dataset <- "Grambank"

df <- rbind(df1, df2)
df$Dataset <- factor(df$Dataset, levels=c("WALS", "Grambank"))

g <- ggplot(df, aes(x=k, y=pval, pch=Dataset, color=Dataset))
g <- g + geom_line(alpha=0.6)
g <- g + geom_point(alpha=0.9, size=2.0)
g <- g + geom_hline(yintercept=0.01, lty=2, alpha=0.8)
g <- g + geom_hline(yintercept=0.05, lty=2, alpha=0.8)
g <- g + scale_y_log10(limits=c(0.005, 1))
g <- g + annotation_logticks(sides="l") 
g <- g + deftheme() 
#g <- g + theme(legend.position=c(0.38, 0.80))
g <- g + theme(legend.position="none")
g <- g + annotate("text", x=-7.5, y=0.008, parse=TRUE, label="italic(p)==0.01", size=3, alpha=0.9)
g <- g + annotate("text", x=-7.5, y=0.04, parse=TRUE, label="italic(p)==0.05", size=3, alpha=0.9)
g <- g + scale_color_sanguche2()
g <- g + ylab(expression(italic(p)*"-value"))
g <- g + xlab(expression("Neighbourhood size relative to optimal"))

g1 <- g

g <- ggplot(df, aes(x=k, y=estimate, pch=Dataset, color=Dataset))
g <- g + geom_line(alpha=0.6)
g <- g + geom_point(alpha=0.9, size=2.0)
g <- g + deftheme() 
g <- g + theme(legend.position=c(0.70, 0.20))
g <- g + scale_color_sanguche2()
g <- g + ylab("Estimate")
g <- g + xlab(expression("Neighbourhood size relative to optimal"))
g <- g + ylim(-0.2, 0.2)

g2 <- g

png("../results/plots/ksweep_mod1_over.png", res=300, width=2000, height=1200)
print(grid.arrange(g2, g1, nrow=1))
dev.off()

