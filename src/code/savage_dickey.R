if (!require(LRO.utilities)) {
  install.packages("devtools")
  devtools::install_github("LudvigOlsen/LRO.utilities")  
}

library(LRO.utilities, quietly=TRUE)

pr = read.csv("tmp/corr_prior.csv")
po = read.csv("tmp/corr_posterior.csv")

result = log(savage_dickey(post=po$posteriorCor, prior=pr$priorCor, Q=0, plot=FALSE)$BF01)

write.csv(as.data.frame(result), "tmp/result.csv", row.names=FALSE)

