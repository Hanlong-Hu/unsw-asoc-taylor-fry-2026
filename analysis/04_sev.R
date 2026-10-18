suppressMessages({library(data.table); library(MASS)})
p <- readRDS("analysis/panel_feat.rds"); p[, covid := as.integer(fy %in% 2019:2020)]
safety <- "patrolled + l_lg + drone_on + campaign_idx + first_aid_cap + pa_system + flags + equip_rating"
env <- "swell_max_m + wind_days + water_temp + rain_mm + turbidity + mh"; mix <- "tourist_ratio + surfer_prop"; stat <- "n_rips + shore_len_m + rocky + fishing + rockpool"
cat("---- coefficients (z) for stat-chars model, free exposure, month factors dropped from print ----\n")
for (yv in c("n_all","n_cc","n_sev")) {
  f <- as.formula(paste(yv, "~ mfac + lvis +", stat, "+ yrs + covid +", safety, "+", env, "+", mix))
  m <- suppressWarnings(glm.nb(f, data=p, control=glm.control(maxit=100)))
  cf <- summary(m)$coefficients; cf <- cf[!grepl("^mfac|Intercept", rownames(cf)),]
  cat("\n", yv, " theta=", m$theta, "\n"); print(round(cf[,c(1,2,4)],3))
}
cat("\n---- Severe: candidate models, CV ----\n")
sets <- list(
 "S0 month + lvis"                    = "mfac + lvis",
 "S1 +season(winter)+lvis"            = "winter + lvis",
 "S2 +patrol+rips+first_aid+tourist"  = "winter + lvis + patrolled + n_rips + first_aid_cap + tourist_ratio",
 "S3 S2 + drone,l_lg,flags,pa"        = "winter + lvis + patrolled + l_lg + drone_on + flags + pa_system + n_rips + first_aid_cap + tourist_ratio",
 "S4 S3 + env + surfer + char"        = paste("winter + lvis + patrolled + l_lg + drone_on + flags + pa_system + first_aid_cap + equip_rating + campaign_idx +", env, "+", mix, "+", stat),
 "S5 mfac + S4 safety/env"            = paste("mfac + lvis + patrolled + l_lg + drone_on + flags + pa_system + first_aid_cap + equip_rating + campaign_idx +", env, "+", mix, "+", stat)
)
folds <- 2020:2025
out <- list()
for (nm in names(sets)) for (fam in c("pois","nb")) {
  cv <- c(); sc <- c()
  for (k in folds) {
    tr <- p[fy<k]; te <- p[fy==k]
    fm <- as.formula(paste("n_sev ~", sets[[nm]]))
    m <- tryCatch(suppressWarnings(if (fam=="pois") glm(fm, poisson, tr) else glm.nb(fm, data=tr, control=glm.control(maxit=100))), error=function(e) NULL)
    if (is.null(m)) {cv<-c(cv,NA); next}
    mu <- predict(m, te, type="response")
    cv <- c(cv, -mean(if (fam=="pois") dpois(te$n_sev, mu, log=TRUE) else dnbinom(te$n_sev, mu=mu, size=m$theta, log=TRUE)))
    # beach ranking: top-10 beaches by predicted severe vs share of actual severe captured in test year
    te[, mu_hat := mu]; b <- te[, .(pred=sum(mu_hat), act=sum(n_sev)), by=beach_nm]; top <- b[order(-pred)][1:10]
    sc <- c(sc, sum(top$act)/max(1,sum(b$act)))
  }
  full <- p[, y:=n_sev]; mf <- suppressWarnings(if (fam=="pois") glm(as.formula(paste("n_sev ~", sets[[nm]])), poisson, p) else glm.nb(as.formula(paste("n_sev ~", sets[[nm]])), data=p, control=glm.control(maxit=100)))
  out[[paste(nm,fam)]] <- data.table(model=nm, fam=fam, cv_nll=mean(cv, na.rm=TRUE), top10_capture=mean(sc), AIC=AIC(mf), BIC=BIC(mf), k=length(coef(mf)))
}
print(rbindlist(out), digits=5)
cat("\nbaseline: random top-10 of 80 beaches captures ~", 10/80, "\n")
