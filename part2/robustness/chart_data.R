# Numbers behind the deck's charts and tables (slides 6, 8, 10, 11, 13, 15 and A1-A5).
suppressMessages({library(MASS); library(dplyr)})
setwd(rprojroot::find_root(rprojroot::has_dir("part1")))
options(width = 200, warn = -1)
set.seed(2027)
pf    <- readRDS("part1/panel_f.rds")
fy27  <- readRDS("part1/forecast_fy2027.rds")
specs <- readRDS("part1/chosen_specs.rds")
m     <- fy27$final$sev
mon   <- as.integer(as.character(pf$mon)); ord <- c(9:12, 1:8)

cat("== Slide 6: by calendar month, 10 years ==\n")
s6 <- data.frame(mon = ord,
  visitors_m_per_yr = round(tapply(pf$visitors, mon, sum)[as.character(ord)] / 10 / 1e6, 2),
  sev_per_100k = round((tapply(pf$n_sev, mon, sum) / tapply(pf$visitors, mon, sum) * 1e5)[as.character(ord)], 3))
print(s6, row.names = FALSE)

cat("\n== Slide 8 / A2: rolling origin FY2022-26, totals and 90% ranges (NB chance + parameters, actual inputs) ==\n")
mk <- function(y, s) as.formula(paste(y, "~", paste(s$rhs, collapse = " + "), "+ offset(log(visitors))"))
ys <- c(mild = "n_mild", cc = "n_cc", sev = "n_sev")
roll <- do.call(rbind, lapply(2022:2026, function(f) do.call(rbind, lapply(names(ys), function(k) {
  tr <- filter(pf, fy < f); te <- filter(pf, fy == f)
  g  <- glm.nb(mk(ys[k], specs[[k]]), data = tr)
  X  <- model.matrix(delete.response(terms(g)), te, xlev = g$xlevels); ok <- !is.na(coef(g))
  B  <- mvrnorm(2000, coef(g)[ok], vcov(g))
  sim <- apply(B, 1, function(b) sum(rnbinom(nrow(te), mu = exp(X[, ok, drop = FALSE] %*% b + log(te$visitors)), size = g$theta)))
  data.frame(fy = f, sev = k, forecast = sum(predict(g, te, type = "response")), lo = quantile(sim, .05), hi = quantile(sim, .95),
             actual = sum(te[[ys[k]]]))
}))))
roll$inside <- roll$actual >= roll$lo & roll$actual <= roll$hi
print(roll %>% mutate(across(c(forecast, lo, hi), ~ round(.x, 1))), row.names = FALSE)
print(roll %>% group_by(sev) %>% summarise(inside = sum(inside), of = n()))

cat("\n== Slide 10: top 20 beaches by FY2027 expected severe, by month ==\n")
fc <- fy27$forecast %>% mutate(m = as.integer(as.character(mon)))
top20 <- fc %>% group_by(beach_nm) %>% summarise(t = sum(mu_sev)) %>% arrange(-t) %>% slice(1:20)
hm <- fc %>% filter(beach_nm %in% top20$beach_nm) %>% select(beach_nm, m, mu_sev) %>%
  tidyr::pivot_wider(names_from = m, values_from = mu_sev) %>% select(beach_nm, all_of(as.character(ord)))
hm <- hm[match(top20$beach_nm, hm$beach_nm), ]
print(as.data.frame(hm %>% mutate(across(-beach_nm, ~ round(.x, 3)), total = round(top20$t, 2))))
cat("max cell:", round(max(as.matrix(hm[, -1])), 3), "\n")

cat("\n== Slide 11 / A1: severe rate ratios per stated change, 95% CI ==\n")
cf <- coef(m); V <- vcov(m)
rr <- function(lab, w) { est <- sum(cf[names(w)] * w); se <- sqrt(drop(t(w) %*% V[names(w), names(w)] %*% w))
  data.frame(term = lab, rr = exp(est), lo = exp(est - 1.96 * se), hi = exp(est + 1.96 * se)) }
d11 <- rbind(
  rr("Swell +1 m", c(swell_max_m = 1)),
  rr("Tourist share +10 pts", c(tourist_ratio = 0.1)),
  rr("Rips +1 per km", c(rips_per_km = 1)),
  rr("Rocky beach", c(rocky = 1)),
  rr("Lifeguard hours x10", c(log_lg = log(10))),
  rr("Drones 0 -> 100 hrs/month", c(log_drone = log1p(100))),
  rr("Campaign 0 -> 0.7", c(campaign_idx = 0.7)),
  rr("Rip flags", c(flags = 1)),
  rr("First aid +10 pts", c(first_aid_cap = 10)),
  rr("PA system", c(pa_system = 1)))
print(d11 %>% mutate(across(-term, ~ round(.x, 2))), row.names = FALSE)
cat("theta (severe):", round(m$theta, 2), "\n")

cat("\n== A3: FY2027 simulated totals (5,000 years) ==\n")
sims <- fy27$sims
print(round(t(sapply(sims[c("mild", "cc", "sev")], quantile, c(.05, .5, .95)))))
h <- table(cut(sims$sev, breaks = seq(-0.5, max(sims$sev) + 0.5, 1), labels = 0:max(sims$sev)))
cat("severe histogram (value:count):", paste(names(h), as.integer(h), sep = ":", collapse = " "), "\n")
