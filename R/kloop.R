kloop <- function(data, dataset) {
  ks <- 1:200

  df <- expand.grid(k=ks, pval=NA, dataset=dataset)

  for (k in ks) {
    datah <- data[data$k == k & data$dataset == dataset, ]
    mod <- summary(glm(Delta_under~status+abs(phi), datah, family=gaussian))
    df[df$k == k, ]$pval <- mod$coefficients["statusnon-interacting", "Pr(>|t|)"]
  }

  df
}
