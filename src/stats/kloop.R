require(emmeans)
require(reshape2)


kloop <- function(data, dataset, var, klim = 10000) {
  data <- data[data$dataset == dataset, ]

  data$k <- data$degree

  data <- data[data$k <= klim, ]

  data <- data[data$status != "unknown", ]

  data$status <- factor(data$status)
  data$status <- relevel(data$status, ref="non-interacting")

  ks <- unique(data$k)

  df <- expand.grid(k=ks, estimate=NA, effect.size=NA, pvalue=NA, dataset=dataset)

  for (k in ks) {
    datah <- data[data$k == k, ]

    datah <- melt(datah, id.vars=c("pair", "status", "skewness"), measure.vars=c("Delta_over", "Delta_under"))

    mod <- lm(value ~ variable*status, datah)

    emm <- emmeans(mod, specs = pairwise ~ variable:status)
    con <- as.data.frame(emm$contrasts)
    eff <- as.data.frame(eff_size(emm, sigma=sigma(mod), edf=mod$df, method="identity"))

    df[df$k == k, ]$estimate = -con[con$contrast == paste0("(", var, " non-interacting) - ", var, " interacting"), ]$estimate
    df[df$k == k, ]$effect.size = -eff[eff$contrast == paste0("((", var, " non-interacting) - ", var, " interacting)"), ]$effect.size
    df[df$k == k, ]$pvalue = con[con$contrast == paste0("(", var, " non-interacting) - ", var, " interacting"), ]$p.value
    #df[df$k == k, ]$estimate = con[con$contrast == paste0(var, " interacting - (", var, " non-interacting)"), ]$estimate
    #df[df$k == k, ]$pvalue = con[con$contrast == paste0(var, " interacting - (", var, " non-interacting)"), ]$p.value
  }

  df
}
