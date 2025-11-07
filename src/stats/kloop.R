require(emmeans)
require(reshape2)
require(dplyr)


do_all_kloops <- function(dfW = fullwals,
			  dfG = fullgram,
			  ks = 1:500) {
	klo_wals_under <- kloop(dfW, "underattested", ks=ks)
	klo_wals_over <- kloop(dfW, "overattested", ks=ks)
	klo_wals <- merge(klo_wals_under, klo_wals_over, by="k")
	klo_wals$dataset <- "WALS"

	klo_gram_under <- kloop(dfG, "underattested", ks=ks)
	klo_gram_over <- kloop(dfG, "overattested", ks=ks)
	klo_gram <- merge(klo_gram_under, klo_gram_over, by="k")
	klo_gram$dataset <- "Grambank"

	klo <- rbind(klo_wals, klo_gram)

	alpha <- 0.05

	klo$esx <- ifelse(klo$pvalue.x < alpha, abs(klo$effect.size.x), 0) +
		ifelse(klo$pvalue.2.x < alpha, abs(klo$effect.size.2.x), 0) +
		ifelse(klo$pvalue.3.x < alpha, abs(klo$effect.size.3.x), 0)

	klo$esy <- ifelse(klo$pvalue.y < alpha, abs(klo$effect.size.y), 0) +
		ifelse(klo$pvalue.2.y < alpha, abs(klo$effect.size.2.y), 0) +
		ifelse(klo$pvalue.3.y < alpha, abs(klo$effect.size.3.y), 0)

	#klo$SNR <- abs(klo$effect.size.x) + abs(klo$effect.size.2.x) + abs(klo$effect.size.3.x) + abs(klo$effect.size.y) + abs(klo$effect.size.2.y) + abs(klo$effect.size.3.y)
	klo$SNR <- klo$esx + klo$esy

	klo
}


kloop <- function(data, variable, ks = 1:50) {
	var <- ifelse(variable == "underattested", "Delta_under", "Delta_over")

	df <- expand.grid(k=ks, estimate=NA, estimate.2=NA, estimate.3=NA, effect.size=NA, effect.size.2=NA, effect.size.3=NA, pvalue=NA, pvalue.2=NA, pvalue.3=NA)

	for (k in ks) {
		#datah <- data %>% group_by(pair) %>% filter(degree == round(sqrt(N)) + k)
		datah <- data %>% group_by(pair) %>% filter(degree == k)

		datah <- melt(datah, id.vars=c("pair", "status"), measure.vars=c("Delta_over", "Delta_under"))

		mod <- lm(value ~ variable*status, datah)

		emm <- emmeans(mod, specs = pairwise ~ variable:status)
		con <- as.data.frame(emm$contrasts)
		eff <- as.data.frame(eff_size(emm, sigma=sigma(mod), edf=mod$df, method="identity"))

		df[df$k == k, ]$estimate = -con[con$contrast == paste0("", var, " control - ", var, " interacting"), ]$estimate
		df[df$k == k, ]$estimate.2 = -con[con$contrast == paste0("", var, " control - ", var, " unknown"), ]$estimate
		df[df$k == k, ]$estimate.3 = con[con$contrast == paste0("", var, " interacting - ", var, " unknown"), ]$estimate
		df[df$k == k, ]$effect.size = -eff[eff$contrast == paste0("(", var, " control - ", var, " interacting)"), ]$effect.size
		df[df$k == k, ]$effect.size.2 = -eff[eff$contrast == paste0("(", var, " control - ", var, " unknown)"), ]$effect.size
		df[df$k == k, ]$effect.size.3 = eff[eff$contrast == paste0("(", var, " interacting - ", var, " unknown)"), ]$effect.size
		df[df$k == k, ]$pvalue = con[con$contrast == paste0("", var, " control - ", var, " interacting"), ]$p.value
		df[df$k == k, ]$pvalue.2 = con[con$contrast == paste0("", var, " control - ", var, " unknown"), ]$p.value
		df[df$k == k, ]$pvalue.3 = con[con$contrast == paste0("", var, " interacting - ", var, " unknown"), ]$p.value
		#df[df$k == k, ]$estimate = con[con$contrast == paste0(var, " interacting - (", var, " non-interacting)"), ]$estimate
		#df[df$k == k, ]$pvalue = con[con$contrast == paste0(var, " interacting - (", var, " non-interacting)"), ]$p.value
	}

	df
}
