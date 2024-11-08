kloop <- function(fulldata, data, dataset, variable = "Delta_under", indvariable = "status") {
  fulldata$status <- relevel(fulldata$status, ref="non-interacting")
  data$status <- relevel(data$status, ref="non-interacting")

  ks <- -10:10

  df <- expand.grid(k=ks, estimate=NA, pval=NA, dataset=dataset)

  for (k in ks) {
    datah <- fulldata[fulldata$dataset == dataset & fulldata$k == fulldata$inflpoint + k, ]
    mod <- summary(lm(eval(parse(text=variable))~eval(parse(text=indvariable))+abs(phi), datah))

    df[df$k == k, ]$estimate <- mod$coefficients[2, "Estimate"]
    df[df$k == k, ]$pval <- mod$coefficients[2, "Pr(>|t|)"]
  }

  df
}
