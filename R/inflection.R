require(tidyverse)


# create directories to save stuff in
try(dir.create("../results/plots", recursive=TRUE))
try(dir.create("../results/tables", recursive=TRUE))


# This loads a dataframe named "combined", which contains all our data
load("../results/combined.RData")


# We restrict attention to neighbourhood sizes smaller than 100
maxk <- 100
maxk_for_lookup <- 100
alldata <- combined[combined$k <= maxk, ]


# This function does one feature pair in one dataset, left to right
do_one_pair <- function(X, data, span = 0.5, degree = 2) {
  # Data here
  dhere <- data[data$pair == X, ]

  # Inflection point
  inflpoint <- NA

  # Fit LOESS to Delta_over + Delta_under
  lo <- loess(Delta_over + Delta_under ~ k, dhere, span=span, degree=degree)
  lof <- lo$fitted

  # Cycle through neighbourhood sizes k, starting from the left,
  # looking for the maximal monotonic connected segment
  for (k in 1:maxk_for_lookup) {
    D <- lof[1:k]

    # if segment is monotonic, update inflection point
    if (all(D == cummin(D)) || all(D == cummax(D))) {
      inflpoint <- k
    }
  }

  # Return
  cbind(dhere, loess=lof, inflpoint)
}



# This function does one feature pair in one dataset, right to left
do_one_pair_RL <- function(X, data, span = 0.5, degree = 2) {
  # Data here
  dhere <- data[data$pair == X, ]

  # Inflection point
  inflpoint <- NA

  # Fit LOESS to Delta_over + Delta_under
  lo <- loess(Delta_over + Delta_under ~ k, dhere, span=span, degree=degree)
  lof <- lo$fitted

  # Cycle through neighbourhood sizes k, starting from the right,
  # looking for the maximal monotonic connected segment
  for (k in maxk_for_lookup:1) {
    D <- lof[k:maxk_for_lookup]

    # if segment is monotonic, update inflection point
    if (all(D == cummin(D)) || all(D == cummax(D))) {
      inflpoint <- k
    }
  }

  # Return
  cbind(dhere, loess=lof, inflpoint)
}


wals_infl <- do.call(rbind, lapply(X=unique(alldata[alldata$dataset=="WALS", ]$pair), FUN=do_one_pair, alldata[alldata$dataset=="WALS", ], span=0.40, degree=2))

gram_infl <- do.call(rbind, lapply(X=unique(alldata[alldata$dataset=="Grambank", ]$pair), FUN=do_one_pair, alldata[alldata$dataset=="Grambank", ], span=0.40, degree=2))

infl <- rbind(wals_infl, gram_infl)


# Plot them

pdf("../results/plots/inflections.pdf", height=8, width=8)

print(ggplot(infl[infl$k==1, ], aes(x=inflpoint, fill=dataset)) + geom_histogram() + facet_wrap(.~dataset))

for (pair in unique(infl$pair)) {

  print(ggplot(infl[infl$pair == pair, ], aes(x=k, y=Delta_over + Delta_under, color=dataset)) + geom_point(size=0.5) + geom_line(aes(x=k, y=loess)) + facet_wrap(.~pair, scales="free") + geom_vline(aes(xintercept=inflpoint, color=dataset), lty=2))
}

dev.off()


# Print inflection points to CSV

out <- infl[, c("pair", "dataset", "inflpoint")]
out <- out[!duplicated(out), ]

# If inflection point == maximum, this means the curve is monotonic across
# the entire range, and we report NA
out$inflpoint <- ifelse(out$inflpoint == maxk_for_lookup, NA, out$inflpoint)

write.csv(out, file="../results/tables/inflection_points.csv", row.names=FALSE)

