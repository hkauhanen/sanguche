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


# read in wide and long versions of the results (run tidyup.R to produce these)
load("../results/combined.RData")


###### OLD VERSION of neighbourhood size plot (medians and quartiles, no individual pairs)

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

##### END OLD VERSION

##### NEW VERSION

data_d <- data %>% group_by(Dataset, Typology, degree) %>% summarize(mean=mean(Delta_dispref), q=quantile(Delta_dispref)[1], Q=quantile(Delta_dispref)[5])

g <- ggplot(data, aes(x=degree, y=Delta_dispref, color=Typology, group=pair_ID)) 
g <- g + geom_point(alpha=0.25) + geom_path(alpha=0.25) 
g <- g + scale_x_log10() 
g <- g + facet_grid(Typology~Dataset) 
g <- g + geom_ribbon(data=data_d, inherit.aes=FALSE, aes(fill=Typology, x=degree, ymin=q, ymax=Q), alpha=0.10) 
g <- g + geom_path(data=data_d, inherit.aes=FALSE, aes(color=Typology, x=degree, y=mean), lwd=2.0) + annotation_logticks(sides="b")
g <- g + scale_color_sanguche() + scale_fill_sanguche()
g <- g + xlab(expression("Neighbourhood size"~italic(k)))
g <- g + ylab(expression("Neighbourhood entropy differential"~Delta))
g <- g + deftheme() 
g <- g + theme(legend.position="none")
png("../results/plots/neighbourhood_dispref.png", res=300, width=1800, height=2500)
print(g)
dev.off()


data10 <- data[data$degree == 10, ]
data10 <- data10 %>% melt(measure.vars=c("Delta_pref", "Delta_dispref"))
levels(data10$variable) <- c("Overrepresented types", "Underrepresented types")

g <- ggplot(data10, aes(x=Typology, fill=Typology, y=value)) 
g <- g + facet_grid(Dataset~variable) 
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
data10 <- melt(data10, measure.vars=c("mean_distance", "sd_distance"))
levels(data10$variable) <- c("Mean distance to neighbour", "S.D. of distance to neighbour")

g <- ggplot(data10, aes(x=value, group=Pair, lty=Pair, fill=Pair, color=Pair))
#g <- g + facet_wrap(variable~., nrow=2)
g <- g + facet_grid(Dataset~variable)
g <- g + geom_density(position="identity", alpha=0.3)
g <- g + scale_fill_aaas() + scale_color_aaas()
g <- g + deftheme()
g <- g + xlab("km") + ylab("")
g <- g + xlim(0, 2500)
g <- g + theme(legend.position=c(0.89, 0.88))


png("../results/plots/distances.png", res=300, width=2000, height=1600)
print(g)
dev.off()
