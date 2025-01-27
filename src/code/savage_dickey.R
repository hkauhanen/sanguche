args <- commandArgs(trailingOnly=TRUE)
dataset <- args[1]

if (!require(LRO.utilities)) {
  install.packages("devtools")
  devtools::install_github("LudvigOlsen/LRO.utilities")  
}

library(LRO.utilities, quietly=TRUE)

pr = read.csv(paste0("tmp/", dataset, "/corr_prior.csv"))
po = read.csv(paste0("tmp/", dataset, "/corr_posterior.csv"))

result = log(savage_dickey(post=po$posteriorCor, prior=pr$priorCor, Q=0, plot=FALSE)$BF01)

write.csv(as.data.frame(result), paste0("tmp/", dataset, "/result.csv"), row.names=FALSE)

