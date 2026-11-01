out <- NULL

for (dataset in c("wals", "grambank", "grambankNEW")) {
	suffix = ""

	if (dataset == "grambankNEW") {
		dataset = "grambank"
		suffix = "_newJager"
	}

	data <- read.csv(paste0("../../results/", dataset, "/joincounts", suffix, ".csv"))

	data$pedigree <- ifelse(data$classification == "dispreferred", "dispreferred", NA)
	data$pedigree <- ifelse(data$class == "control" & data$attestation == "underattested", "control underattested", data$pedigree)

	if (dataset == "wals")
		data$dataset <- "WALS"
	else if (dataset == "grambank")
		if (suffix == "_newJager")
			data$dataset <- "Grambank NEW"
		else
			data$dataset <- "Grambank"

	out <- rbind(out, data)
}

write.csv(out, paste0("../../results/joincounts_all.csv"), row.names=FALSE)
