wals_files <- list.files(path="wals/code/mrbayes/logs/", pattern="*.csv", full.names=TRUE)
gram_files <- list.files(path="grambank/code/mrbayes/logs/", pattern="*.csv", full.names=TRUE)

read_one <- function(X) {
  df <- read.csv(X, header=FALSE)
  names(df) <- c("family", "timestamp", "generations", "ASDSF", "maxPSRF")
  df
}

wals <- do.call(rbind, lapply(X=wals_files, FUN=read_one))
wals$dataset <- "WALS"

gram <- do.call(rbind, lapply(X=gram_files, FUN=read_one))
gram$dataset <- "Grambank"

logs <- rbind(wals, gram)
