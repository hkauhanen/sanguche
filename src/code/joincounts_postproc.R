args <- commandArgs(trailingOnly=TRUE)
dataset <- args[1]

data <- read.csv(paste0("../../results/", dataset, "/joincounts.csv"))

data$pedigree <- ifelse(data$classification == "dispreferred", "dispreferred", NA)
data$pedigree <- ifelse(data$class == "control" & data$attestation == "underattested", "control underattested", data$pedigree)

write.csv(data, paste0("../../results/", dataset ,"/joincounts_processed.csv"), row.names=FALSE)
