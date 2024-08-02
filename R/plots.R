if (!require(pacman)) install.packages("pacman")
pacman::p_load(tidyverse, ggsci, gridExtra, reshape)

try(dir.create("../results/plots", recursive=TRUE))

deftheme <- function() {
  g <- theme_bw()
  g <- g + theme(panel.grid.major=element_blank(), panel.grid.minor=element_blank())
  g <- g + theme(axis.text=element_text(color="black"))
  g <- g + theme(strip.text=element_text(size=12, hjust=0), strip.background=element_blank())
  g
}

wals <- read.csv("../results/wals/results.csv")
wals$Dataset <- "WALS"
grambank <- read.csv("../results/grambank/results.csv")
grambank$Dataset <- "Grambank"

data <- rbind(wals, grambank)

data$Typology <- factor(data$okay, levels=c("interacting", "unknown", "non-interacting"))
data$Dataset <- factor(data$Dataset, levels=c("WALS", "Grambank"))
data$Delta_pref <- data$H_pref - data$H
data$Delta_dispref <- data$H_dispref - data$H

data_d <- data %>% group_by(Dataset, Typology, degree) %>% summarize(median=median(Delta_dispref), q=quantile(Delta_dispref)[2], Q=quantile(Delta_dispref)[4])


g <- ggplot(data_d, aes(x=degree, color=Typology, group=Typology))
g <- g + facet_wrap(.~Dataset, nrow=2)
g <- g + geom_ribbon(aes(fill=Typology, ymin=q, ymax=Q), alpha=0.15, color=NA)
g <- g + geom_line(aes(y=median, lty=Typology), lwd=1.0)
g <- g + scale_x_log10()
g <- g + annotation_logticks(sides="b")
g <- g + scale_fill_jco() + scale_color_jco()
g <- g + deftheme()
g <- g + xlab("Neighbourhood size") + ylab(expression("Neighbourhood entropy differential"~Delta))
g <- g + theme(legend.position=c(0.85, 0.90))

png("../results/plots/neighbourhood_dispref.png", res=300, width=1800, height=2500)
print(g)
dev.off()


data10 <- data[data$degree == 10, ]
#data10 <- data10 %>% group_by(Dataset) %>% melt(measure.vars=c("Delta_pref", "Delta_dispref"))
data10 <- data10 %>% melt(measure.vars=c("Delta_pref", "Delta_dispref"))
levels(data10$variable) <- c("Overrepresented types", "Underrepresented types")

g <- ggplot(data10, aes(x=Typology, fill=Typology, y=value)) 
g <- g + facet_grid(Dataset~variable) 
g <- g + geom_boxplot(alpha=0.35)
g <- g + scale_fill_jco()
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

g <- ggplot(data10, aes(x=value, fill=Dataset, color=Dataset))
g <- g + facet_wrap(variable~., nrow=2)
g <- g + geom_density(lwd=0.6, adjust=1.0, position="identity", alpha=0.3)
g <- g + scale_fill_nejm() + scale_color_nejm()
g <- g + deftheme()
g <- g + xlab("km") + ylab("")
g <- g + xlim(0, 2500)
g <- g + theme(legend.position=c(0.89, 0.88))

png("../results/plots/distances.png", res=300, width=2000, height=1600)
print(g)
dev.off()
