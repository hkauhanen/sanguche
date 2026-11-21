require(stringr)

dumbbell_plot <- function(data, nbins = 20, quantile = FALSE) {
  # reorder pedigree factor to get more sensible plot defaults
  #levels(data$pedigree) <- c("dispreferred", "control under")

  # make frequency bins
  if (quantile) {
    quants <- quantile(data$frequency, probs=(1:nbins)/nbins)
    quants <- c(min(data$frequency) - 0.0001, quants[1:length(quants)], max(data$frequency + 0.0001))
    data$freqbin <- cut(data$frequency, quants)
  } else {
    data$freqbin <- cut(data$frequency, nbins)
  }

  df = data %>% group_by(freqbin, pedigree) %>% summarize(mjc = mean(joincount))

  # compute the handles of the dumbbells
  df_group1 = data %>% group_by(pedigree) %>% group_split %>% .[[1]]
  df_group2 = data %>% group_by(pedigree) %>% group_split %>% .[[2]]

  df_group1 <- df_group1 %>% group_by(freqbin) %>% summarize(mjc1 = mean(joincount))
  df_group2 <- df_group2 %>% group_by(freqbin) %>% summarize(mjc2 = mean(joincount))

  df_groups <- merge(df_group1, df_group2, by = "freqbin", all = TRUE)

  # prettify frequency bin labels
  df$freqbin <- str_replace(df$freqbin, ",", " ... ") %>%
    substring(first=2) %>%
    substring(first=1, last=nchar(.)-1)

  df_groups$freqbin <- str_replace(df_groups$freqbin, ",", " ... ") %>%
    substring(first=2) %>%
    substring(first=1, last=nchar(.)-1)

  g <- ggplot(df, aes(x=freqbin, y=mjc, color=pedigree, pch=pedigree))
  g <- g + geom_segment(data=df_groups, inherit.aes=FALSE, aes(x=freqbin, xend=freqbin, y=mjc1, yend=mjc2), color = "darkgrey", linewidth=0.8)
  g <- g + geom_point(size=1.3, stroke=1.3)
  g <- g + xlab("frequency bin") + ylab("mean join score")
  g <- g + coord_flip()
  g <- g + scale_shape_manual(values=c(19, 1))
  g <- g + scale_color_manual(values=c(pal_npg()(10)[2], pal_npg()(10)[1]))
  g <- g + theme_bw()

  g
}
