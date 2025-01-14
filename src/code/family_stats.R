args <- commandArgs(trailingOnly=TRUE)
dataset <- args[1]

sink(paste0("../../", dataset, "/family_statistics.txt"))

data <- read.csv(paste0("../../", dataset, "/data/famFrequencies.csv"))

cat(paste("Languages:", sum(data$nrow), "\n"))
cat(paste("Phylogenies:", nrow(data), "\n"))
cat(paste("Non-isolates:", nrow(data[data$nrow > 1, ]), "\n"))
cat(paste("Isolates:", nrow(data[data$nrow == 1, ]), "\n"))

sink()

