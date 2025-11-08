require(stringr)

annotation_df = expand.grid(variable=c("underattested", "overattested"), dataset=c("WALS", "Grambank"), status=c("interacting", "unknown"))
annotation_df$xmin = "control"
annotation_df$y_position = 0.12
annotation_df$annotations = ""

for (i in 1:nrow(annotation_df)) {
	first_comparand <- paste(annotation_df[i,]$variable, annotation_df[i,]$status)
	second_comparand <- paste(annotation_df[i,]$variable, "control")

	if (annotation_df[i,]$status == "interacting") {
		annotation_df[i,]$y_position <- 0.14
	}

	if (annotation_df[i,]$dataset == "WALS") {
		mod <- mod_wals
	} else {
		mod <- mod_gram
	}

	pval <- mod$con[str_detect(mod$con$contrast, first_comparand) & str_detect(mod$con$contrast, second_comparand), ]$p.value
	print(mod$con[str_detect(mod$con$contrast, first_comparand) & str_detect(mod$con$contrast, second_comparand), ])
	print(first_comparand)
	print(second_comparand)
	print(pval)

	stars <- "NS"

	if (pval < 0.05)
		stars <- "*"
	if (pval < 0.01)
		stars <- "**"
	if (pval < 0.001)
		stars <- "***"

	annotation_df[i,]$annotations <- stars
}


make_boxplot <- function(wals, gram) {
	all <- rbind(wals, gram)
	all$overattested <- all$Delta_over
	all$underattested <- all$Delta_under
	all <- melt(all, measure.vars=c("underattested", "overattested"))
	all$status <- factor(all$status, levels=c("interacting", "control", "unknown"))
	all$dataset <- factor(all$dataset, levels=c("WALS", "Grambank"))

	g <- ggplot(all, aes(x=status, y=value, fill=status))
	g <- g + geom_boxplot(outlier.size=0.75)
	g <- g + facet_wrap(variable~dataset, nrow=1)
	g <- g + geom_signif(family = "Times",
			     data = annotation_df,
			     aes(annotations=annotations, xmin=xmin, xmax=status, y_position=y_position),
			     manual  = TRUE,
			     map_signif_level = c("***" = 0.001, "**" = 0.01, "*" = 0.05),
			     size = 0.3,
			     textsize = 3.0)
	g <- g + ylab("Neighborhood entropy differential")
	g <- g + xlab("")
	g <- g + deftheme()
	g <- g + theme(axis.text.x=element_text(angle=35, size=10, hjust=1))
	g <- g + guides(fill=FALSE)
	g <- g + scale_fill_manual(values=paulscolors2[c(2,3,1)])
	g <- g + ylim(-0.05, 0.15)
	
	g
}

