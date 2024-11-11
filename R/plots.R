# dependencies
require(tidyverse)
require(ggsci)
require(gridExtra)
require(reshape2)
require(ggplot2)

source("kvsk.R")


# create directory to save plots in
try(dir.create("../results/plots", recursive=TRUE))


# default theme
deftheme <- function() {
  g <- theme_bw()
  g <- g + theme(panel.grid.major=element_blank(), panel.grid.minor=element_blank())
  g <- g + theme(axis.text=element_text(color="black"))
  g <- g + theme(strip.text=element_text(size=12, hjust=0), strip.background=element_blank())
  g
}


# default colour palettes
mypal <- pal_futurama(alpha=1.0)(3)
mypal <- mypal[c(3,1,2)]

scale_color_sanguche <- function() {
	scale_color_manual(values=mypal)
}

scale_fill_sanguche <- function() {
	scale_fill_manual(values=mypal)
}


# read in wide and long versions of the results (run make merge to produce these)
load("../results/combined.RData")


# rename
data <- combined
ldata <- combined_long



# remove cross of ctrl feature with other ctrl feature
data <- data[data$pair != "PolQ & NegM", ]



###### OLD VERSION of neighbourhood size plot (medians and quartiles, no individual pairs)
if (1 == 0) {
data_d <- data %>% group_by(Dataset, Typology, degree) %>% summarize(median=median(Delta_dispref), q=quantile(Delta_dispref)[2], Q=quantile(Delta_dispref)[4])


g <- ggplot(data_d, aes(x=degree, color=Typology, group=Typology))
g <- g + facet_wrap(.~Dataset, nrow=2)
g <- g + geom_ribbon(aes(fill=Typology, ymin=q, ymax=Q), alpha=0.15, color=NA)
g <- g + geom_line(aes(y=median, lty=Typology), lwd=1.0)
g <- g + scale_x_log10()
g <- g + annotation_logticks(sides="b")
g <- g + scale_fill_sanguche() + scale_color_sanguche()
g <- g + deftheme()
g <- g + xlab("Neighbourhood size") + ylab(expression("Neighbourhood entropy differential"~Delta))
g <- g + theme(legend.position=c(0.85, 0.90))
}
##### END OLD VERSION


##### NEW VERSION

data_d <- data %>% group_by(dataset, status, k) %>% summarize(mean=mean(Delta_under), q=quantile(Delta_under)[1], Q=quantile(Delta_under)[5])

g <- ggplot(data[data$k %in% round(exp(seq(from=log(1), to=log(200), length.out=20))), ], aes(x=k, y=Delta_under, color=status, group=pair)) 
g <- g + geom_point(alpha=0.25) + geom_path(alpha=0.25) 
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


wals_inflpoint <- round(max_inflection_point(data, "WALS"))
gram_inflpoint <- round(max_inflection_point(data, "Grambank"))



wals <- data[data$dataset == "WALS" & data$k == wals_inflpoint, ]
gram <- data[data$dataset == "Grambank" & data$k == gram_inflpoint, ]
data_onek <- rbind(wals, gram)

data_onek_long <- melt(data_onek, measure.vars=c("Delta_over", "Delta_under"))
levels(data_onek_long$variable) <- c("Overrepresented types", "Underrepresented types")

g <- ggplot(data_onek_long, aes(x=status, fill=status, y=value)) 
g <- g + facet_grid(dataset~variable) 
g <- g + geom_boxplot(alpha=0.35)
g <- g + scale_fill_sanguche()
g <- g + deftheme()
g <- g + xlab("")
g <- g + ylab(expression("Neighbourhood entropy differential"~Delta))
g <- g + theme(legend.position=c(0.15, 0.89))

png("../results/plots/boxplot.png", res=300, width=1800, height=2000)
print(g)
dev.off()



#### OLD
if (1 == 0) {

data10 <- data[data$degree == 10, ]
data_onek_long <- melt(data_onek, measure.vars=c("mean_distance", "sd_distance"))
levels(data_onek_long$variable) <- c("Mean distance to neighbour", "S.D. of distance to neighbour")

g <- ggplot(data_onek_long, aes(x=value, group=control, lty=control, fill=control, color=control))
#g <- g + facet_wrap(variable~., nrow=2)
g <- g + facet_grid(dataset~variable)
g <- g + geom_density(position="identity", alpha=0.3)
g <- g + scale_fill_aaas() + scale_color_aaas()
g <- g + deftheme()
g <- g + xlab("km") + ylab("")
g <- g + xlim(0, 1000)
g <- g + theme(legend.position=c(0.89, 0.88))
}


### NEW



wals_meanmean <- median(data[data$dataset == "WALS" & data$k == 20, ]$mean_distance)
grambank_meanmean <- median(data[data$dataset == "Grambank" & data$k == 42, ]$mean_distance)
meanmeans <- data.frame(dataset=c("WALS", "Grambank"), x=c(wals_meanmean, grambank_meanmean), k=c(20, 42))

g <- ggplot(data[data$k %in% c(1, 10, 20, 42, 100, 200), ], aes(x=mean_distance, lty=factor(k), color=factor(k), fill=factor(k), group=factor(k))) 
g <- g + geom_density(position="identity", alpha=0.4) 
g <- g + facet_wrap(.~factor(dataset, levels=c("WALS", "Grambank")), nrow=2) 
g <- g + deftheme() 
g <- g + theme(legend.position=c(0.85, 0.83))
g <- g + scale_fill_npg() 
g <- g + scale_color_npg() 
g <- g + xlab("Mean distance to neighbour") 
g <- g + guides(color=guide_legend(expression("Neighbourhood size"~italic(k))), fill=guide_legend(expression("Neighbourhood size"~italic(k))), lty=guide_legend(expression("Neighbourhood size"~italic(k))))
g <- g + geom_vline(data=meanmeans, aes(xintercept=x), color="black", alpha=0.5)


png("../results/plots/distances.png", res=300, width=2000, height=2000)
print(g)
dev.off()






source("kloop.R")

df1 <- kloop(data, "WALS", "Delta_under", "status")
df1$Dataset <- "WALS"

df2 <- kloop(data, "Grambank", "Delta_under", "status")
df2$Dataset <- "Grambank"

df <- rbind(df1, df2)
df$Dataset <- factor(df$Dataset, levels=c("WALS", "Grambank"))

df$estimate <- ifelse(df$estimate > 0, "> 0", "< 0")

g <- ggplot(df, aes(x=k, y=pval, color=Dataset))#, group=estimate, color=estimate)) 
#g <- g + geom_path(inherit.aes=FALSE, aes(x=k, y=pval), color="grey") 
#g <- g + geom_point(size=2.0) 
g <- g + geom_path(alpha=0.5)
g <- g + geom_point(alpha=0.5)
g <- g + geom_hline(yintercept=0.01, lty=2) 
g <- g + geom_hline(yintercept=0.05, lty=3) 
g <- g + scale_y_log10(limits=c(0.005, 1))
g <- g + scale_x_log10()
g <- g + annotation_logticks(sides="bl") 
g <- g + deftheme() 
g <- g + theme(legend.position="top")#c(0.90, 0.30))
g <- g + geom_text(inherit.aes=FALSE, nudge_y=0.1, data=data.frame(x=c(1.5, 1.5), y=c(0.01, 0.05), label=c("p = 0.01", "p = 0.05")), aes(x=x, y=y, label=label))
g <- g + scale_color_aaas()
#g <- g + facet_wrap(.~Dataset, nrow=2)
g <- g + ylab(expression(italic(p)*"-value"))
g <- g + xlab(expression("Neighbourhood size"~italic(k)))

png("../results/plots/ksweep_mod1_under.png", res=300, width=2000, height=1700)
print(g)
dev.off()


df1 <- kloop(data, "WALS", "Delta_over", "status")
df1$Dataset <- "WALS"

df2 <- kloop(data, "Grambank", "Delta_over", "status")
df2$Dataset <- "Grambank"

df <- rbind(df1, df2)
df$Dataset <- factor(df$Dataset, levels=c("WALS", "Grambank"))

df$estimate <- ifelse(df$estimate > 0, "> 0", "< 0")

g <- ggplot(df, aes(x=k, y=pval, color=Dataset))#, group=estimate, color=estimate)) 
#g <- g + geom_path(inherit.aes=FALSE, aes(x=k, y=pval), color="grey") 
#g <- g + geom_point(size=2.0) 
g <- g + geom_path(alpha=0.5)
g <- g + geom_point(alpha=0.5)
g <- g + geom_hline(yintercept=0.01, lty=2) 
g <- g + geom_hline(yintercept=0.05, lty=3) 
g <- g + scale_y_log10(limits=c(0.005, 1))
g <- g + scale_x_log10()
g <- g + annotation_logticks(sides="bl") 
g <- g + geom_text(inherit.aes=FALSE, nudge_y=0.1, data=data.frame(x=c(1.5, 1.5), y=c(0.01, 0.05), label=c("p = 0.01", "p = 0.05")), aes(x=x, y=y, label=label))
g <- g + deftheme() 
g <- g + theme(legend.position="top")#c(0.90, 0.30))
g <- g + scale_color_aaas()
#g <- g + facet_wrap(.~Dataset, nrow=2)
g <- g + ylab(expression(italic(p)*"-value"))
g <- g + xlab(expression("Neighbourhood size"~italic(k)))

png("../results/plots/ksweep_mod1_over.png", res=300, width=2000, height=1700)
print(g)
dev.off()


