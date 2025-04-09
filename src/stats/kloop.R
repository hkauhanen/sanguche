kloop <- function(data, dataset, variable = "Delta_under", indvariable = "status", klim = 2000) {
  data$status <- factor(data$status)
  data$status <- relevel(data$status, ref="non-interacting")

  data <- data[data$k <= klim, ]

  data <- data[data$dataset == dataset, ]

  ks <- unique(data$k)

  df <- expand.grid(k=ks, estimate=NA, pvalue=NA, dataset=dataset)

  for (k in ks) {
    datah <- data[data$k == k, ]

    mod1 <- summary(lm(eval(parse(text=variable))~eval(parse(text=indvariable))+skewness, datah))

    if (k == 1000) {
      print(mod1)
    }
    
    df[df$k == k, ]$estimate <- mod1$coefficients[2, "Estimate"]
    df[df$k == k, ]$pvalue <- mod1$coefficients[2, "Pr(>|t|)"]
  }

  df
}
