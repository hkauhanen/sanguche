kloop <- function(data, dataset, variable = "Delta_under", indvariable = "status") {
  data$status <- relevel(data$status, ref="non-interacting")

  ks <- 1:200

  df <- expand.grid(k=ks, estimate=NA, pval=NA, dataset=dataset)

  for (k in ks) {
    datah <- data[data$k == k & data$dataset == dataset, ]
    mod <- summary(lm(eval(parse(text=variable))~eval(parse(text=indvariable))+abs(phi), datah))
    df[df$k == k, ]$estimate <- mod$coefficients[2, "Estimate"]
    df[df$k == k, ]$pval <- mod$coefficients[2, "Pr(>|t|)"]
  }

  df
}
