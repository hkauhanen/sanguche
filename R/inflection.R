require(tidyverse)


# create directories to save stuff in
try(dir.create("../results/plots", recursive=TRUE))
try(dir.create("../results/tables", recursive=TRUE))


# This loads a dataframe named "combined", which contains all our data
load("../results/combined.RData")


# We restrict attention to neighbourhood sizes smaller than 100
maxk <- 100
maxk_for_lookup <- 50
alldata <- combined[combined$k <= maxk, ]


# Check whether vector of numbers is increasing or decreasing
increasing <- function(x, strict = TRUE) {
  L <- length(x)

  if (strict) {
    return(all(x[1:(L-1)] < x[2:L]))
  } else {
    return(all(x[1:(L-1)] <= x[2:L]))
  }
}

decreasing <- function(x, strict = TRUE) {
  L <- length(x)

  if (strict) {
    return(all(x[1:(L-1)] > x[2:L]))
  } else {
    return(all(x[1:(L-1)] >= x[2:L]))
  }
}



# This function does one feature pair. Window = how many far to look
# for extremum detection (on each side)
do_one_pair <- function(X, data, window = 5, span = 0.5, degree = 2) {
  # Data here
  dhere <- data[data$pair == X, ]

  # Extrema (potential inflection points)
  extrema <- NULL
  inflpoint <- NA

  # Fit LOESS to Delta_over + Delta_under
  lo <- loess(Delta_over + Delta_under ~ k, dhere, span=span, degree=degree)
  lof <- lo$fitted

  # Cycle through points in the LOESS curve, identifying extremum points
  for (k in (window + 1):(maxk_for_lookup - window - 1)) {
    Dunder <- lof[(k - window):(k - 1)]
    Dover <- lof[(k + 1):(k + window)]

    # k is an extremum if either (Dunder is increasing & Dover is decreasing) or
    # (Dunder is decreasing & Dover is increasing)
    if ((increasing(Dunder, strict=TRUE) && decreasing(Dover, strict=TRUE)) ||
        (decreasing(Dunder, strict=TRUE) && increasing(Dover, strict=TRUE))) {
      extrema <- c(extrema, k)
    }

    # Inflection point is the extremum with the highest amplitude (distance from zero).
    # If there are no extrema, we return an NA.
    if (length(extrema) > 0) {
      amps <- data.frame(k=extrema, amp=abs(lof[extrema]))
      amps <- amps[order(amps$amp, decreasing=TRUE), ]
      inflpoint <- amps[1, ]$k
    }
  }

  # Return
  cbind(dhere, loess=lof, inflpoint)
}


win <- 3
sp <- 0.2
deg <- 2

wals_infl <- do.call(rbind, lapply(X=unique(alldata[alldata$dataset=="WALS", ]$pair), FUN=do_one_pair, alldata[alldata$dataset=="WALS", ], window=win, span=sp, degree=deg))

gram_infl <- do.call(rbind, lapply(X=unique(alldata[alldata$dataset=="Grambank", ]$pair), FUN=do_one_pair, alldata[alldata$dataset=="Grambank", ], window=win, span=sp, degree=deg))

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

