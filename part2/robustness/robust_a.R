suppressMessages({library(MASS); library(dplyr)})
setwd(rprojroot::find_root(rprojroot::has_dir("part1")))
options(width = 200, warn = -1)
pf    <- readRDS("part1/panel_f.rds")
specs <- readRDS("part1/chosen_specs.rds")
rhs   <- specs$sev$rhs
lev   <- c("log_lg", "log_drone", "campaign_idx", "flags", "first_aid_cap", "pa_system")
mk    <- function(y, r) as.formula(paste(y, "~", paste(r, collapse = " + "), "+ offset(log(visitors))"))
fit   <- function(d, r = rhs, y = "n_sev") glm.nb(mk(y, r), data = d)
co    <- function(m) round(coef(m)[lev], 3)

cat("== A1. Lever coefficients: full data, rolling training windows, leave-one-year-out ==\n")
full <- fit(pf)
tab <- rbind(full = co(full),
             do.call(rbind, lapply(2022:2026, function(f) setNames(co(fit(filter(pf, fy < f))), lev))) %>% `rownames<-`(paste0("train<", 2022:2026)),
             do.call(rbind, lapply(2017:2026, function(f) co(fit(filter(pf, fy != f))))) %>% `rownames<-`(paste0("drop ", 2017:2026)))
print(tab)
cat("ranges (excluding full):\n"); print(apply(tab[-1, ], 2, range))

cat("\n== A2. Within-beach: beach fixed effects instead of traits ==\n")
traits <- c("surfer_prop", "tourist_ratio", "rips_per_km", "rocky", "fishing", "rockpool", "shore_len_m")
fe <- fit(pf, c(setdiff(rhs, traits), "factor(beach_nm)"))
s  <- summary(fe)$coefficients
print(round(s[lev, ], 3)); cat("AIC traits:", round(AIC(full)), " AIC beach FE:", round(AIC(fe)), "\n")
cat("Serious (close call + severe), traits model:\n")
pf$n_ser <- pf$n_cc + pf$n_sev
ser <- fit(pf, rhs, "n_ser"); print(round(summary(ser)$coefficients[lev, ], 3))
ser_fe <- fit(pf, c(setdiff(rhs, traits), "factor(beach_nm)"), "n_ser")
cat("Serious, beach FE:\n"); print(round(summary(ser_fe)$coefficients[lev, ], 3))

cat("\n== A3. Where does drone variation come from? ==\n")
bd <- pf %>% group_by(beach_nm) %>% summarise(ever = any(drone_hrs > 0), first_fy = suppressWarnings(min(fy[drone_hrs > 0])),
                                            share_months = mean(drone_hrs > 0))
cat("Beaches ever flying drones:", sum(bd$ever), " never:", sum(!bd$ever), "\n")
cat("First drone year at drone beaches:\n"); print(table(bd$first_fy[bd$ever]))
cat("Share of months flown at drone beaches (quantiles):", round(quantile(bd$share_months[bd$ever], c(0, .25, .5, .75, 1)), 2), "\n")
cat("Severe per M visits, drone beach-months vs not:",
    round(with(pf, c(drone = sum(n_sev[drone_hrs > 0]) / sum(visitors[drone_hrs > 0]) * 1e6,
                     none = sum(n_sev[drone_hrs == 0]) / sum(visitors[drone_hrs == 0]) * 1e6)), 3), "\n")
# switchers: before vs after first drone month, same beaches
sw <- pf %>% left_join(bd, by = "beach_nm") %>% filter(ever, first_fy > 2017) %>%
  mutate(after = drone_hrs > 0) %>% group_by(after) %>%
  summarise(sev = sum(n_sev), ser = sum(n_ser), vis = sum(visitors)) %>%
  mutate(sev_per_m = sev / vis * 1e6, ser_per_m = ser / vis * 1e6)
cat("Beaches that started drones after FY2017, months without vs with drones:\n"); print(as.data.frame(sw))

cat("\n== A4. Do the lever terms help out-of-sample? Rolling origin FY2022-26, severe NB log score ==\n")
ls_nb <- function(m, d) -sum(dnbinom(d$n_sev, mu = predict(m, d, type = "response"), size = m$theta, log = TRUE))
variants <- list(full = rhs, no_drone = setdiff(rhs, "log_drone"), no_lg = setdiff(rhs, "log_lg"),
                 no_safety = setdiff(rhs, c(lev, "equip_rating")),
                 drone_any = c(rhs, "I(drone_hrs > 0)"), drone_sqrt = c(setdiff(rhs, "log_drone"), "sqrt(drone_hrs)"),
                 drone_lin = c(setdiff(rhs, "log_drone"), "drone_hrs"))
sc <- sapply(variants, function(r) sum(sapply(2022:2026, function(f) ls_nb(fit(filter(pf, fy < f), r), filter(pf, fy == f)))))
print(round(sc - sc["full"], 2)); cat("(positive = worse than the full model; total over 5 test years)\n")

cat("\n== A5. Functional form for drones, full data ==\n")
for (nm in c("full", "drone_any", "drone_sqrt", "drone_lin")) {
  m <- fit(pf, variants[[nm]]); cf <- coef(m)
  rr <- exp(sum(c(cf["log_drone"] * log1p(120), cf["I(drone_hrs > 0)TRUE"], cf["sqrt(drone_hrs)"] * sqrt(120), cf["drone_hrs"] * 120), na.rm = TRUE))
  rr2 <- exp(sum(c(cf["log_drone"] * (log1p(120) - log1p(60)), cf["sqrt(drone_hrs)"] * (sqrt(120) - sqrt(60)), cf["drone_hrs"] * 60), na.rm = TRUE))
  cat(sprintf("%-10s AIC %.0f  RR 0->120 hrs %.2f  RR 60->120 hrs %.2f\n", nm, AIC(m), rr, rr2))
}
dir.create("part2/robustness/out", showWarnings = FALSE)
saveRDS(list(fe = coef(fe), full = coef(full), any = coef(fit(pf, variants$drone_any)), sqrt = coef(fit(pf, variants$drone_sqrt))),
        "part2/robustness/out/alt_coefs.rds")
