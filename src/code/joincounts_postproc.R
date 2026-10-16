data <- read.csv("../../results/wals/joincounts.csv")

data$pedigree <- ifelse(data$classification == "dispreferred", "dispreferred", NA)
data$pedigree <- ifelse(data$class == "control" & data$attestation == "underattested", "control underattested", data$pedigree)

write.csv(data, "../../results/wals/joincounts_processed.csv", row.names=FALSE)
