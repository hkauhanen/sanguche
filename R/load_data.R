# load (and rename) dataframe "combined", which contains all our data
load("../results/combined.RData")
data <- combined
data <- data[data$pair != "PolQ & NegM", ]
data <- data[data$pair != "Gen & Pas", ]

# make "non-interacting" the reference level of "status" factor
data$status <- relevel(data$status, ref="non-interacting")

# inflection points
infl <- read.csv("../results/tables/inflection_points.csv")
ip_wals <- round(mean(infl[infl$dataset == "WALS" & !is.na(infl$inflpoint), ]$inflpoint))
ip_grambank <- round(mean(infl[infl$dataset == "Grambank" & !is.na(infl$inflpoint), ]$inflpoint))

print(ip_wals)
print(ip_grambank)

# restrict to final choice of k
#wals <- data[data$dataset == "WALS" & data$k == ip_wals, ]
#gram <- data[data$dataset == "Grambank" & data$k == ip_grambank, ]

wals <- data[data$dataset == "WALS", ]
gram <- data[data$dataset == "Grambank", ]

wals <- merge(wals, infl, by="pair")
gram <- merge(gram, infl, by="pair")

wals$inflpoint <- ifelse(is.na(wals$inflpoint), round(mean(wals$inflpoint, na.rm=TRUE)), wals$inflpoint)
gram$inflpoint <- ifelse(is.na(gram$inflpoint), round(mean(gram$inflpoint, na.rm=TRUE)), gram$inflpoint)

# copy data to fulldata
fulldata <- rbind(wals, gram)

# restrict to individual inflection points
wals <- wals[wals$k == wals$inflpoint, ]
gram <- gram[gram$k == gram$inflpoint, ]

data <- rbind(wals, gram)

data$dataset <- data$dataset.x
fulldata$dataset <- fulldata$dataset.x

# change order of factor levels
data$status <- factor(data$status, levels=c("interacting", "unknown", "non-interacting"))
data$dataset <- factor(data$dataset, levels=c("WALS", "Grambank"))

fulldata$status <- factor(fulldata$status, levels=c("interacting", "unknown", "non-interacting"))
fulldata$dataset <- factor(fulldata$dataset, levels=c("WALS", "Grambank"))
