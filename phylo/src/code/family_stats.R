sink("../../family_statistics.txt")

wals <- read.csv("../../wals/data/famFrequencies.csv")
gram <- read.csv("../../grambank/data/famFrequencies.csv")

cat("WALS\n====\n")

cat(paste("Languages:", sum(wals$nrow), "\n"))
cat(paste("Phylogenies:", nrow(wals), "\n"))
cat(paste("Non-isolates:", nrow(wals[wals$nrow > 1, ]), "\n"))
cat(paste("Isolates:", nrow(wals[wals$nrow == 1, ]), "\n"))

cat("\n\n")

cat("Grambank\n========\n")

cat(paste("Languages:", sum(gram$nrow), "\n"))
cat(paste("Phylogenies:", nrow(gram), "\n"))
cat(paste("Non-isolates:", nrow(gram[gram$nrow > 1, ]), "\n"))
cat(paste("Isolates:", nrow(gram[gram$nrow == 1, ]), "\n"))

sink()


