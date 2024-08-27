kloop <- function(data) {
  ks <- 1:200

  df <- expand.grid(k=ks, pval=NA)

  for (k in ks) {
    datah <- data[data$degree == k, ]
    mod <- summary(glm((H_dispref - H)~okay+abs(phi), datah, family=gaussian))
    df[df$k == k, ]$pval <- mod$coefficients[2, "Pr(>|t|)"]
  }

  df
}
