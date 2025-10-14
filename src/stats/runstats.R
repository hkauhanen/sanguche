require(rmarkdown)

#dataset = commandArgs(trailingOnly=TRUE)[1]

#render("stats.Rmd", output_file=paste0("../../results/stats_", dataset, ".html"), params=list(dataset=dataset))
render("stats_test.Rmd", output_file="../../results/stats.html")

