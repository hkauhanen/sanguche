# dependencies
require(tidyverse)
require(ggsci)
require(gridExtra)
require(reshape2)
require(ggplot2)

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

g <- ggplot(data, aes(x=k, y=Delta_under, color=status, group=pair)) 
g <- g + geom_point(alpha=0.25) + geom_path(alpha=0.25) 
g <- g + scale_x_log10() 
g <- g + facet_grid(status~dataset) 
g <- g + geom_ribbon(data=data_d, inherit.aes=FALSE, aes(fill=status, x=k, ymin=q, ymax=Q), alpha=0.10) 
g <- g + geom_path(data=data_d, inherit.aes=FALSE, aes(color=status, x=k, y=mean), lwd=2.0) + annotation_logticks(sides="b")
g <- g + scale_color_sanguche() + scale_fill_sanguche()
g <- g + xlab(expression("Neighbourhood size"~italic(k)))
g <- g + ylab(expression("Neighbourhood entropy differential"~Delta))
g <- g + deftheme() 
g <- g + theme(legend.position="none")
png("../results/plots/neighbourhood_dispref.png", res=300, width=1800, height=2500)
print(g)
dev.off()


wals <- data[data$dataset == "WALS" & data$k == 8, ]
gram <- data[data$dataset == "Grambank" & data$k == 8, ]
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
g <- g + xlim(0, 4000)
g <- g + theme(legend.position=c(0.89, 0.88))


png("../results/plots/distances.png", res=300, width=2000, height=1600)
print(g)
dev.off()



source("kvsk.R")

wals_kvsk <- kvsk3(data, "WALS")
gram_kvsk <- kvsk3(data, "Grambank")

data_kvsk <- rbind(wals_kvsk, gram_kvsk)

g <- ggplot(data_kvsk, aes(x=k, y=diff, color=dataset, group=dataset)) 
g <- g + geom_point(alpha=0.5) + facet_wrap(.~dataset, ncol=2) 
g <- g + geom_smooth(span=0.1, se=FALSE) 
g <- g + deftheme() 
g <- g + scale_color_aaas() 
g <- g + geom_vline(data=data.frame(xintercept=c(23,36), dataset=c("Grambank", "WALS")), inherit.aes=FALSE, aes(xintercept=xintercept), lty=1, lwd=1.0, alpha=0.4) 
g <- g + theme(legend.position="none") 
g <- g + xlab(expression("neighbourhood size"~italic(k))) 
g <- g + ylab(expression("no. of differing sites between adjacent"~italic(k))) 
g <- g + geom_text(data=data.frame(dataset=c("Grambank", "WALS"), x=c(23, 36), label=c("italic(k) == 23", "italic(k) == 36")), inherit.aes=FALSE, aes(x=x, y=38, label=label), nudge_x=25, alpha=0.7, size=4.5, parse=TRUE)


png("../results/plots/kvsk.png", res=300, width=2000, height=1000)
print(g)
dev.off()


