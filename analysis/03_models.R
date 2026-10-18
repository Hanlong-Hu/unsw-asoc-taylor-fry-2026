# Compare candidate count GLMs with rolling-origin (expanding window) validation by Sep-Aug year
suppressMessages({library(data.table); library(MASS)})
p <- readRDS("analysis/panel_feat.rds")
p[, covid := as.integer(fy %in% 2019:2020)]
p[, lvis_c := lvis - mean(lvis)]
# term blocks
safety <- "patrolled + l_lg + drone_on + campaign_idx + first_aid_cap + pa_system + flags + equip_rating"
env    <- "swell_max_m + wind_days + water_temp + rain_mm + turbidity + mh"
mix    <- "tourist_ratio + surfer_prop"
stat   <- "n_rips + shore_len_m + rocky + fishing + rockpool"
junk   <- "icecream_visits + n_bins"
RHS <- list(
  "M0 beach+month (offset)"      = list(f=paste("beach + mfac"), off=TRUE),
  "M1 +safety (offset)"          = list(f=paste("beach + mfac +", safety), off=TRUE),
  "M2 +safety+env (offset)"      = list(f=paste("beach + mfac +", safety, "+", env), off=TRUE),
  "M3 M2+mix, free exposure"     = list(f=paste("beach + mfac + lvis +", safety, "+", env, "+", mix), off=FALSE),
  "M4 M3 + trend/covid"          = list(f=paste("beach + mfac + lvis + yrs + covid +", safety, "+", env, "+", mix), off=FALSE),
  "M5 static chars (no beach FE)"= list(f=paste("mfac + lvis +", stat, "+ yrs + covid +", safety, "+", env, "+", mix), off=FALSE),
  "M6 M5 + junk(ice cream,bins)" = list(f=paste("mfac + lvis +", stat, "+ yrs + covid +", safety, "+", env, "+", mix, "+", junk), off=FALSE),
  "M7 M4 + interactions"         = list(f=paste("beach + mfac + lvis + yrs + covid +", safety, "+", env, "+", mix, "+ patrolled:winter + l_lg:lvis_c + swell_max_m:rip_dens"), off=FALSE)
)
fit_nb <- function(f, d, off) {
  fm <- as.formula(paste("y ~", f, if (off) "+ offset(lvis)" else ""))
  m <- tryCatch(suppressWarnings(glm.nb(fm, data=d, control=glm.control(maxit=100))), error=function(e) NULL)
  m
}
nll <- function(m, d) { mu <- predict(m, d, type="response"); -mean(dnbinom(d$y, mu=mu, size=m$theta, log=TRUE)) }
pdev <- function(m, d) { mu <- predict(m, d, type="response"); y <- d$y; mean(2*(ifelse(y>0, y*log(y/mu), 0) - (y-mu))) }
folds <- 2022:2025   # test FY; train = all earlier FY
run <- function(yvar) {
  res <- list()
  for (nm in names(RHS)) {
    sp <- RHS[[nm]]; cv <- c(); cd <- c(); tot <- c()
    for (k in folds) {
      tr <- copy(p[fy < k]); te <- copy(p[fy == k]); tr[, y := get(yvar)]; te[, y := get(yvar)]
      m <- fit_nb(sp$f, tr, sp$off); if (is.null(m)) { cv <- c(cv, NA); cd <- c(cd, NA); tot <- c(tot, NA); next }
      cv <- c(cv, nll(m, te)); cd <- c(cd, pdev(m, te))
      tot <- c(tot, sum(predict(m, te, type="response"))/sum(te$y))
    }
    full <- copy(p); full[, y := get(yvar)]; mf <- fit_nb(sp$f, full, sp$off)
    res[[nm]] <- data.table(model=nm, cv_nll=mean(cv), cv_pdev=mean(cd), pred_over_act=mean(tot), AIC=AIC(mf), BIC=BIC(mf), k=length(coef(mf)), theta=mf$theta)
  }
  rbindlist(res)
}
for (yv in c("n_all","n_mild","n_cc")) { cat("\n=====", yv, "=====\n"); print(run(yv), digits=5) }
saveRDS(RHS, "analysis/rhs.rds")
