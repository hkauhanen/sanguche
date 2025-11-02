deftheme_withminorgrid <- function() {
    g <- theme_bw()
    #  g <- g + theme(panel.grid.major=element_blank(), panel.grid.minor=element_blank())
    #g <- g + theme(panel.grid.minor=element_blank())
    g <- g + theme(axis.text=element_text(color="black"))
    g <- g + theme(strip.text=element_text(size=10), strip.background=element_blank())
    #g <- g + theme(strip.text=element_text(size=12, hjust=0), strip.background=element_blank()  )
    g <- g + theme(text=element_text(family="Times"))
    g <- g + theme(plot.title=element_text(size=11))
    g
}

paulscolors <- c("#0077BB", "#33BBEE", "#009988", "#EE7733", "#CC3311", "#EE3377")


breaks <- 10^(-10:10)
minor_breaks <- rep(1:9, 21)*(10^rep(-10:10, each=9))

klops$UA.CvI <- klops$effect.size.x
klops$OA.CvI <- klops$effect.size.y
klops$UA.CvU <- klops$effect.size.2.x
klops$OA.CvU <- klops$effect.size.2.y
klops$UA.IvU <- klops$effect.size.3.x
klops$OA.IvU <- klops$effect.size.3.y

klops_W <- klops[klops$dataset == "WALS" & klops$k %in% round(exp(seq(from=log(1), to=log(500), length.out=26))), ]
klops_G <- klops[klops$dataset == "Grambank" & klops$k %in% round(exp(seq(from=log(1), to=log(500), length.out=23))), ]

klops_Wm <- melt(klops_W, measure.vars=c("SNR", "UA.CvI", "OA.CvI", "UA.CvU", "OA.CvU", "UA.IvU", "OA.IvU"), variable.name="Contrast")
klops_Gm <- melt(klops_G, measure.vars=c("SNR", "UA.CvI", "OA.CvI", "UA.CvU", "OA.CvU", "UA.IvU", "OA.IvU"), variable.name="Contrast")

g1 <- ggplot(klops_Wm, aes(x=k)) 
g1 <- g1 + geom_line(aes(y=value, lty=Contrast, linewidth=Contrast, color=Contrast))
g1 <- g1 + geom_point(aes(y=value, shape=Contrast, color=Contrast, size=Contrast))
g1 <- g1 + geom_vline(xintercept=32, lty=2)
g1 <- g1 + scale_linewidth_manual(values=c(0.8, rep(0.5, 6)))
g1 <- g1 + scale_shape_manual(values=c(20, 1:6))
g1 <- g1 + scale_size_manual(values=c(2.5, rep(1.2, 6)))
g1 <- g1 + scale_color_manual(values=c("#000000", paulscolors))
#g1 <- g1 + geom_line(data=klops_W, aes(x=k, y=SNR), color="black", linewidth=0.8)
#g1 <- g1 + geom_point(data=klops_W, aes(x=k, y=SNR), color="black", pch=20, size=2.5)
g1 <- g1 + deftheme_withminorgrid()
g1 <- g1 + scale_x_log10(breaks=breaks, minor_breaks=minor_breaks) + annotation_logticks(sides="b") + ggtitle("(a) WALS") + xlab(expression("Neighborhood size (" * italic(k) * ")")) + ylab("Effect size") + theme(text=element_text(family="Times")) + theme(legend.title=element_blank())

g2 <- g1

g1 <- ggplot(klops_Gm, aes(x=k)) 
g1 <- g1 + geom_line(aes(y=value, lty=Contrast, linewidth=Contrast, color=Contrast))
g1 <- g1 + geom_point(aes(y=value, shape=Contrast, color=Contrast, size=Contrast))
g1 <- g1 + geom_vline(xintercept=13, lty=2)
g1 <- g1 + scale_linewidth_manual(values=c(0.8, rep(0.5, 6)))
g1 <- g1 + scale_shape_manual(values=c(20, 1:6))
g1 <- g1 + scale_size_manual(values=c(2.5, rep(1.2, 6)))
g1 <- g1 + scale_color_manual(values=c("#000000", paulscolors))
#g1 <- g1 + geom_line(data=klops_W, aes(x=k, y=SNR), color="black", linewidth=0.8)
#g1 <- g1 + geom_point(data=klops_W, aes(x=k, y=SNR), color="black", pch=20, size=2.5)
g1 <- g1 + deftheme_withminorgrid()
g1 <- g1 + scale_x_log10(breaks=breaks, minor_breaks=minor_breaks) + annotation_logticks(sides="b") + ggtitle("(b) Grambank") + xlab(expression("Neighborhood size (" * italic(k) * ")")) + ylab("Effect size") + theme(legend.title=element_blank())

png("../../results/plots/SNR_complex.png", width=3000, height=4000, res=550)
grid.arrange(g2, g1, nrow=2)
dev.off()
