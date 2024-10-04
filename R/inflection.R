require(tidyverse)
require(broom)
require(pixiedust)
require(emmeans)


# This loads a dataframe named "combined", which contains all our data
load("../results/combined.RData")


# We restrict attention to neighbourhood sizes smaller than 50
maxk <- 100
alldata <- combined[combined$k <= maxk, ]


# This function does one feature pair in one dataset
do_one_pair <- function(X, data) {
  # Data here
  dhere <- data[data$pair == X, ]

  # Inflection point
  inflpoint <- NA

  # Fit LOESS to Delta_over + Delta_under
  lo <- loess(Delta_over + Delta_under ~ k, dhere, span=0.5, degree=2)#, weights=((100:1)/100)^2)
  lof <- lo$fitted

  # Cycle through neighbourhood sizes k, starting from the right,
  # looking for the maximal monotonic connected segment
  maxk_for_lookup <- 50
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


wals_infl <- do.call(rbind, lapply(X=unique(alldata[alldata$dataset=="WALS", ]$pair), FUN=do_one_pair, alldata[alldata$dataset=="WALS", ]))

gram_infl <- do.call(rbind, lapply(X=unique(alldata[alldata$dataset=="Grambank", ]$pair), FUN=do_one_pair, alldata[alldata$dataset=="Grambank", ]))

infl <- rbind(wals_infl, gram_infl)


# Plot them

pdf("inflections.pdf", height=8, width=8)

print(ggplot(infl[infl$k==1, ], aes(x=inflpoint, fill=dataset)) + geom_histogram() + facet_wrap(.~dataset))

for (pair in unique(infl$pair)) {

  print(ggplot(infl[infl$pair == pair, ], aes(x=k, y=Delta_over + Delta_under, color=dataset)) + geom_point(size=0.5) + geom_line(aes(x=k, y=loess)) + facet_wrap(.~pair, scales="free") + geom_vline(aes(xintercept=inflpoint, color=dataset), lty=2))
}

dev.off()


# Print means
wi <- wals_infl$inflpoint
wi <- wi[wi != 1]
gi <- gram_infl$inflpoint
gi <- gi[gi != 1]
print(paste("WALS mean (non-1):", mean(wi)))
print(paste("Grambank mean (non-1):", mean(gi)))

print(paste("WALS max (non-1):", max(wi)))
print(paste("Grambank max (non-1):", max(gi)))


