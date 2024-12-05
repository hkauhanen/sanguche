kloop <- function(data, dataset, variable = "Delta_under", indvariable = "status") {
  #data$status <- relevel(data$status, ref="non-interacting")
  data <- data[data$status != "non-interacting", ]

  ks <- 1:500

  df <- expand.grid(k=ks, estimate=NA, pval=NA, DAIC=NA, dataset=dataset)

  for (k in ks) {
    datah <- data[data$k == k & data$dataset == dataset, ]

    #mod1 <- summary(lm(eval(parse(text=variable))~eval(parse(text=indvariable))+abs(phi), datah))
    #mod1 <- summary(lm(eval(parse(text=variable))~eval(parse(text=indvariable))+abs(phi), datah))
    mod1 <- summary(lm(eval(parse(text=variable))~eval(parse(text=indvariable)), datah))
    mod2a <- lm(eval(parse(text=variable))~abs(phi), datah)
    mod2b <- lm(eval(parse(text=variable))~abs(corrected_phi), datah)

    if (k == 1) {
      print(mod1)
    }
    
    df[df$k == k, ]$estimate <- mod1$coefficients[2, "Estimate"]
    df[df$k == k, ]$pval <- mod1$coefficients[2, "Pr(>|t|)"]
    df[df$k == k, ]$DAIC <- AIC(mod2a) - AIC(mod2b)
  }

  df
}
