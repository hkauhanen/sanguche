require(emmeans)
require(reshape2)
require(dplyr)


kloop <- function(data, variable, ks = -30:50) {
	var <- ifelse(variable == "underattested", "Delta_under", "Delta_over")

	df <- expand.grid(k=ks, estimate=NA, effect.size=NA, effect.size.2=NA, effect.size.3=NA, pvalue=NA)

	for (k in ks) {
		datah <- data %>% group_by(pair) %>% filter(degree == round(sqrt(N)) + k)

		datah <- melt(datah, id.vars=c("pair", "status"), measure.vars=c("Delta_over", "Delta_under"))

		mod <- lm(value ~ variable*status, datah)

		emm <- emmeans(mod, specs = pairwise ~ variable:status)
		con <- as.data.frame(emm$contrasts)
		eff <- as.data.frame(eff_size(emm, sigma=sigma(mod), edf=mod$df, method="identity"))

		df[df$k == k, ]$estimate = con[con$contrast == paste0("", var, " control - ", var, " interacting"), ]$estimate
		df[df$k == k, ]$effect.size = eff[eff$contrast == paste0("(", var, " control - ", var, " interacting)"), ]$effect.size
		df[df$k == k, ]$effect.size.2 = eff[eff$contrast == paste0("(", var, " control - ", var, " unknown)"), ]$effect.size
		df[df$k == k, ]$effect.size.3 = eff[eff$contrast == paste0("(", var, " interacting - ", var, " unknown)"), ]$effect.size
		df[df$k == k, ]$pvalue = con[con$contrast == paste0("", var, " control - ", var, " interacting"), ]$p.value
		#df[df$k == k, ]$estimate = con[con$contrast == paste0(var, " interacting - (", var, " non-interacting)"), ]$estimate
		#df[df$k == k, ]$pvalue = con[con$contrast == paste0(var, " interacting - (", var, " non-interacting)"), ]$p.value
	}

	df
}
