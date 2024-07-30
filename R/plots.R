library(tidyverse)
library(ggsci)
library(gridExtra)
library(reshape2)


wals <- read.csv("../results/wals/results.csv")
grambank <- read.csv("../results/grambank/results.csv")

wals$Typology <- factor(wals$okay, levels=c("interacting", "unknown", "non-interacting"))
wals$Delta_pref <- wals$H_pref - wals$H
wals$Delta_dispref <- wals$H_dispref - wals$H

grambank$Typology <- factor(grambank$okay, levels=c("interacting", "unknown", "non-interacting"))
grambank$Delta_pref <- grambank$H_pref - grambank$H
grambank$Delta_dispref <- grambank$H_dispref - grambank$H

wals_d <- wals %>% group_by(Typology, degree) %>% summarize(median=median(Delta_dispref), q=quantile(Delta_dispref)[2], Q=quantile(Delta_dispref)[4])
grambank_d <- grambank %>% group_by(Typology, degree) %>% summarize(median=median(Delta_dispref), q=quantile(Delta_dispref)[2], Q=quantile(Delta_dispref)[4])


g <- ggplot(wals_d, aes(x=degree, color=Typology, group=Typology))
g <- g + geom_ribbon(aes(fill=Typology, ymin=q, ymax=Q), alpha=0.15, color=NA)
g <- g + geom_line(aes(y=median, lty=Typology), lwd=1.0)
g <- g + scale_x_log10()
g <- g + annotation_logticks(sides="bt")
g <- g + scale_fill_jco() + scale_color_jco()
g <- g + theme_bw() + theme(panel.grid.minor=element_blank(), axis.text=element_text(color="black"))
g <- g + xlab("Neighbourhood size") + ylab(expression("Neighbourhood entropy differential"~Delta))
g <- g + ggtitle("(A) Underrepresented types, WALS")

h <- g

g <- ggplot(grambank_d, aes(x=degree, color=Typology, group=Typology))
g <- g + geom_ribbon(aes(fill=Typology, ymin=q, ymax=Q), alpha=0.15, color=NA)
g <- g + geom_line(aes(y=median, lty=Typology), lwd=1.0)
g <- g + scale_x_log10()
g <- g + annotation_logticks(sides="bt")
g <- g + scale_fill_jco() + scale_color_jco()
g <- g + theme_bw() + theme(panel.grid.minor=element_blank(), axis.text=element_text(color="black"))
g <- g + xlab("Neighbourhood size") + ylab(expression("Neighbourhood entropy differential"~Delta))
g <- g + ggtitle("(B) Underrepresented types, Grambank")

png("../results/plots/neighbourhood_dispref.png", res=300, width=2000, height=3000)
print(grid.arrange(h, g, ncol=1))
dev.off()



wals10 <- melt(wals[wals$degree == 10, ], measure.vars=c("Delta_pref", "Delta_dispref"))
wals10$Dataset <- "WALS"
grambank10 <- melt(grambank[grambank$degree == 10, ], measure.vars=c("Delta_pref", "Delta_dispref"))
grambank10$Dataset <- "Grambank"
data10 <- rbind(wals10, grambank10)

data10$Dataset <- factor(data10$Dataset, levels=c("WALS", "Grambank"))
data10$Typology <- factor(data10$Typology, levels=c("interacting", "unknown", "non-interacting"))
levels(data10$variable) <- c("Overrepresented types", "Underrepresented types")

g <- ggplot(data10, aes(x=Typology, fill=Typology, y=value)) 
g <- g + facet_grid(Dataset~variable) 
g <- g + geom_boxplot(alpha=0.35)
g <- g + scale_fill_jco()
g <- g + theme_bw()
g <- g + theme(axis.text=element_text(color="black"))
g <- g + theme(strip.text=element_text(size=12), strip.background=element_blank())
g <- g + xlab("")
g <- g + ylab(expression("Neighbourhood entropy differential"~Delta))

png("../results/plots/boxplot.png", res=300, width=2000, height=2000)
print(g)
dev.off()



wals10 <- melt(wals[wals$degree == 10, ], measure.vars=c("mean_distance", "sd_distance"))
wals10$Dataset <- "WALS"
grambank10 <- melt(grambank[grambank$degree == 10, ], measure.vars=c("mean_distance", "sd_distance"))
grambank10$Dataset <- "Grambank"
data10 <- rbind(wals10, grambank10)

data10$Dataset <- factor(data10$Dataset, levels=c("WALS", "Grambank"))
data10$Typology <- factor(data10$Typology, levels=c("interacting", "unknown", "non-interacting"))
levels(data10$variable) <- c("Mean distance to neighbour", "S.D. of distance to neighbour")

g <- ggplot(data10, aes(x=value, fill=Dataset, color=Dataset))
g <- g + facet_wrap(variable~., nrow=2)
g <- g + geom_density(lwd=0.6, adjust=1.0, position="identity", alpha=0.3)
g <- g + scale_fill_nejm() + scale_color_nejm()
g <- g + theme_bw()
g <- g + theme(axis.text=element_text(color="black"))
g <- g + theme(strip.text=element_text(size=12), strip.background=element_blank())
g <- g + xlab("km") + ylab("")
g <- g + xlim(0, 2500)

png("../results/plots/distances.png", res=300, width=2000, height=1600)
print(g)
dev.off()
