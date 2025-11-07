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
paulscolors <- paulscolors[c(1, 4, 5)]


breaks <- 10^(-10:10)
minor_breaks <- rep(1:9, 21)*(10^rep(-10:10, each=9))

#klops <- klops[klops$k %in% round(exp(seq(from=log(1), to=log(500), length.out=20))), ]


klops_W_UA <- melt(klops[klops$dataset == "WALS", ], measure.vars=c("SNR", "effect.size.x", "effect.size.2.x", "effect.size.3.x"), variable.name="Contrast")
#klops_W_UA_p <- melt(klops[klops$dataset == "WALS", ], measure.vars=c("pvalue.x", "pvalue.2.x", "pvalue.3.x"), variable.name="Contrast.2")
#klops_W_UA <- merge(klops_W_UA, klops_W_UA_p, by="k")
#klops_W_UA$value.y <- ifelse(klops_W_UA$value.y < 0.05, 10.0, 1.0)

klops_W_OA <- melt(klops[klops$dataset == "WALS", ], measure.vars=c("SNR", "effect.size.y", "effect.size.2.y", "effect.size.3.y"), variable.name="Contrast")

klops_G_UA <- melt(klops[klops$dataset == "Grambank", ], measure.vars=c("SNR", "effect.size.x", "effect.size.2.x", "effect.size.3.x"), variable.name="Contrast")

klops_G_OA <- melt(klops[klops$dataset == "Grambank", ], measure.vars=c("SNR", "effect.size.y", "effect.size.2.y", "effect.size.3.y"), variable.name="Contrast")

#klops_W <- klops[klops$dataset == "WALS" & klops$k %in% round(exp(seq(from=log(1), to=log(500), length.out=26))), ]
#klops_G <- klops[klops$dataset == "Grambank" & klops$k %in% round(exp(seq(from=log(1), to=log(500), length.out=23))), ]

#klops_W <- klops[klops$dataset == "WALS" & klops$k %in% c(1:10, (1:10)*10, (1:10)*100), ]
#klops_G <- klops[klops$dataset == "Grambank" & klops$k %in% c(1:10, (1:10)*10, (1:10)*100), ]

#klops_Wm <- melt(klops_W, measure.vars=c("SNR", "UA.IvC", "OA.IvC", "UA.UvC", "OA.UvC", "UA.IvU", "OA.IvU"), variable.name="Contrast")
#klops_Gm <- melt(klops_G, measure.vars=c("SNR", "UA.IvC", "OA.IvC", "UA.UvC", "OA.UvC", "UA.IvU", "OA.IvU"), variable.name="Contrast")

deflabels <- c("SNR", "int v. ctrl", "unkn v. ctrl", "int v. unkn")

g <- ggplot(klops_W_UA, aes(x=k)) 
g <- g + geom_line(aes(y=value, lty=Contrast, linewidth=Contrast, color=Contrast))
g <- g + geom_point(aes(y=value, size=Contrast, shape=Contrast, color=Contrast))
g <- g + geom_vline(xintercept=wals_ideal, lty=2)
g <- g + scale_linewidth_manual(values=c(0.8, rep(0.5, 6)))
g <- g + scale_shape_manual(values=c(20, 1:6))
g <- g + scale_size_manual(values=c(1.5, rep(1.2, 6)))
g <- g + scale_color_manual(values=c("#000000", paulscolors), labels=c("IvC", "UvC", "IvU"))
g <- g + deftheme_withminorgrid()
g <- g + scale_x_log10(breaks=breaks, minor_breaks=minor_breaks) + annotation_logticks(sides="b")
g <- g + ggtitle("(a) WALS, underattested") + xlab(expression("Neighborhood size (" * italic(k) * ")")) + ylab("Effect size") + theme(text=element_text(family="Times")) + theme(legend.title=element_blank())
g <- g + theme(legend.position="none")

g1 <- g

g <- ggplot(klops_W_OA, aes(x=k)) 
g <- g + geom_line(aes(y=value, lty=Contrast, linewidth=Contrast, color=Contrast))
g <- g + geom_point(aes(y=value, size=Contrast, shape=Contrast, color=Contrast))
g <- g + geom_vline(xintercept=wals_ideal, lty=2)
g <- g + scale_linewidth_manual(values=c(0.8, rep(0.5, 6)))
g <- g + scale_shape_manual(values=c(20, 1:6), labels=deflabels)
g <- g + scale_size_manual(values=c(1.5, rep(1.2, 6)))
g <- g + scale_color_manual(values=c("#000000", paulscolors), labels=deflabels)
g <- g + guides(lty="none", size="none", linewidth="none")
g <- g + deftheme_withminorgrid()
g <- g + scale_x_log10(breaks=breaks, minor_breaks=minor_breaks) + annotation_logticks(sides="b")
g <- g + ggtitle("(b) WALS, overattested") + xlab(expression("Neighborhood size (" * italic(k) * ")")) + ylab("Effect size") + theme(text=element_text(family="Times")) + theme(legend.title=element_blank())

g2 <- g

g <- ggplot(klops_G_UA, aes(x=k)) 
g <- g + geom_line(aes(y=value, lty=Contrast, linewidth=Contrast, color=Contrast))
g <- g + geom_point(aes(y=value, size=Contrast, shape=Contrast, color=Contrast))
g <- g + geom_vline(xintercept=gram_ideal, lty=2)
g <- g + scale_linewidth_manual(values=c(0.8, rep(0.5, 6)))
g <- g + scale_shape_manual(values=c(20, 1:6))
g <- g + scale_size_manual(values=c(1.5, rep(1.2, 6)))
g <- g + scale_color_manual(values=c("#000000", paulscolors))
g <- g + deftheme_withminorgrid()
g <- g + scale_x_log10(breaks=breaks, minor_breaks=minor_breaks) + annotation_logticks(sides="b")
g <- g + ggtitle("(c) Grambank, underattested") + xlab(expression("Neighborhood size (" * italic(k) * ")")) + ylab("Effect size") + theme(text=element_text(family="Times")) + theme(legend.title=element_blank())
g <- g + theme(legend.position="none")

g3 <- g

g <- ggplot(klops_G_OA, aes(x=k)) 
g <- g + geom_line(aes(y=value, lty=Contrast, linewidth=Contrast, color=Contrast))
g <- g + geom_point(aes(y=value, size=Contrast, shape=Contrast, color=Contrast))
g <- g + geom_vline(xintercept=gram_ideal, lty=2)
g <- g + scale_linewidth_manual(values=c(0.8, rep(0.5, 6)))
g <- g + scale_shape_manual(values=c(20, 1:6), labels=deflabels)
g <- g + scale_size_manual(values=c(1.5, rep(1.2, 6)))
g <- g + scale_color_manual(values=c("#000000", paulscolors), labels=deflabels)
g <- g + guides(lty="none", size="none", linewidth="none")
g <- g + deftheme_withminorgrid()
g <- g + scale_x_log10(breaks=breaks, minor_breaks=minor_breaks) + annotation_logticks(sides="b")
g <- g + ggtitle("(d) Grambank, overattested") + xlab(expression("Neighborhood size (" * italic(k) * ")")) + ylab("Effect size") + theme(text=element_text(family="Times")) + theme(legend.title=element_blank())

g4 <- g


png("../../results/plots/SNR_complex.png", width=3500, height=3000, res=500)
grid.arrange(g1, g2, g3, g4, nrow=2, widths=c(0.7, 1.0))
dev.off()
