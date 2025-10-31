png("../../tmp/SNR.png", width=3000, height=1700, res=500)

g1 <- ggplot(klops[klops$dataset == "WALS" & klops$k %in% round(exp(seq(from=log(1), to=log(500), length.out=25))), ], aes(x=k, y=SNR)) + geom_line() + geom_point() + scale_x_log10(breaks=breaks, minor_breaks=minor_breaks) + annotation_logticks(sides="b") + theme_bw() + ggtitle("(a) WALS") + xlab(expression("Neighborhood size (" * italic(k) * ")")) + ylab("Signal to noise ratio (SNR)") + theme(text=element_text(family="Times"))

g2 <- ggplot(klops[klops$dataset == "Grambank" & klops$k %in% round(exp(seq(from=log(1), to=log(500), length.out=20))), ], aes(x=k, y=SNR)) + geom_line() + geom_point() + scale_x_log10(breaks=breaks, minor_breaks=minor_breaks) + annotation_logticks(sides="b") + theme_bw() + ggtitle("(b) Grambank") + xlab(expression("Neighborhood size (" * italic(k) * ")")) + ylab("Signal to noise ratio (SNR)") + theme(text=element_text(family="Times"))

grid.arrange(g1, g2, nrow=1)

dev.off()
