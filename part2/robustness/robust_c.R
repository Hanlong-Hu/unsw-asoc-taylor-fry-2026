suppressMessages({library(MASS); library(dplyr)})
setwd(rprojroot::find_root(rprojroot::has_dir("part1")))
tmp <- "part2/robustness/out"; dir.create(tmp, showWarnings = FALSE)
options(width = 200, warn = -1)
fy27 <- readRDS("part1/forecast_fy2027.rds"); m <- fy27$final$sev
win  <- fy27$newdata %>% left_join(fy27$forecast %>% select(beach_nm, mon, mu0 = mu_sev), by = c("beach_nm", "mon")) %>%
  arrange(beach_nm, month_date)
beach_ids <- unique(win$beach_nm); pc_ids <- sort(unique(win$postcode))
bi <- match(win$beach_nm, beach_ids); pci <- match(win$postcode, pc_ids); cal <- as.integer(as.character(win$mon))
fl_mask <- as.numeric(win$flags == 0)
camp_gain <- ifelse(cal %in% c(11, 12, 1, 2), pmax(0.7 - win$campaign_idx, 0), 0)
LG_CAP <- max(readRDS("part1/panel_f.rds")$lg_hrs)
score <- function(p, bb) {
  lg <- pmin(p$lg_add, pmax(LG_CAP - win$lg_hrs, 0))
  d <- bb[["log_lg"]] * (log1p(win$lg_hrs + lg) - log1p(win$lg_hrs)) + bb[["log_drone"]] * (log1p(win$drone_hrs + p$dh_v) - log1p(win$drone_hrs)) +
       bb[["flags"]] * fl_mask * p$flag_v[bi] + bb[["campaign_idx"]] * camp_gain * p$camp_v[pci]
  sum(win$mu0) - sum(win$mu0 * exp(d))
}
S <- lapply(c("base", "drone_half", "beach_fe", "robust_only", "pessimistic"), function(n) readRDS(file.path(tmp, paste0("scen_", n, ".rds"))))
names(S) <- sapply(S, `[[`, "name")
cat("== C1. Fixed base plan scored under each coefficient set, vs re-optimised for that set ==\n")
out <- t(sapply(names(S), function(n) c(base_plan = score(S$base, S[[n]]$b), reoptimised = S[[n]]$avoided)))
print(round(cbind(out, kept_share = out[, 1] / out[, 2]), 2))

cat("\n== C2. 95% CI ends for each lever (one at a time, base plan) ==\n")
se <- sqrt(diag(vcov(m)))
for (v in c("log_lg", "log_drone", "campaign_idx", "flags")) {
  lo <- hi <- coef(m); lo[v] <- coef(m)[v] + 1.96 * se[v]; hi[v] <- coef(m)[v] - 1.96 * se[v]
  cat(sprintf("%-13s weak end %.2f | strong end %.2f\n", v, score(S$base, lo), score(S$base, hi)))
}
cat("All four levers at weak end:", round(score(S$base, { x <- coef(m); for (v in c("log_lg", "log_drone", "campaign_idx", "flags")) x[v] <- x[v] + 1.96 * se[v]; x }), 2), "\n")

cat("\n== C3. Drones: model-implied vs raw before/after at beaches that started flying ==\n")
pf <- readRDS("part1/panel_f.rds")
start <- pf %>% group_by(beach_nm) %>% summarise(first_fy = suppressWarnings(min(fy[drone_hrs > 0])))
sw <- pf %>% left_join(start, by = "beach_nm") %>% filter(is.finite(first_fy), first_fy > 2017, drone_hrs > 0)
mu_with <- predict(m, sw, type = "response")
mu_wo   <- predict(m, sw %>% mutate(drone_hrs = 0, log_drone = 0), type = "response")
cat("Model: drone months at those beaches would have", round(sum(mu_wo), 1), "severe without drones vs", round(sum(mu_with), 1),
    "with, a", round(100 * (1 - sum(mu_with) / sum(mu_wo))), "% cut\n")
cat("Actual severe in those months:", sum(sw$n_sev), "| mean drone hrs when flying:", round(mean(sw$drone_hrs)), "\n")
# same comparison controlling for everything else: actual vs model-without-drones
cat("Observed / predicted-without-drones:", round(sum(sw$n_sev) / sum(mu_wo), 2), " (model says", round(sum(mu_with) / sum(mu_wo), 2), ")\n")
# serious version with serious model
pf$n_ser <- pf$n_cc + pf$n_sev
ms <- glm.nb(update(formula(m), n_ser ~ .), data = pf)
sw2 <- pf %>% left_join(start, by = "beach_nm") %>% filter(is.finite(first_fy), first_fy > 2017, drone_hrs > 0)
cat("Serious: observed / predicted-without-drones:", round(sum(sw2$n_ser) / sum(predict(ms, sw2 %>% mutate(log_drone = 0), type = "response")), 2),
    " (model with drones:", round(sum(predict(ms, sw2, type = "response")) / sum(predict(ms, sw2 %>% mutate(log_drone = 0), type = "response")), 2), ")\n")

cat("\n== C4. Base plan: where the drone money goes ==\n")
b <- S$base
newb <- b$ydr_v[bi] == 1
cat("Avoided from drones at new-drone beaches:", round(score(list(lg_add = 0, dh_v = b$dh_v * newb, flag_v = 0 * b$flag_v, camp_v = 0 * b$camp_v), coef(m)), 2),
    " at existing:", round(score(list(lg_add = 0, dh_v = b$dh_v * !newb, flag_v = 0 * b$flag_v, camp_v = 0 * b$camp_v), coef(m)), 2), "\n")
cat("Extra drone hrs vs FY2026 fleet total:", round(sum(b$dh_v)), "vs", round(sum(win$drone_hrs)), "\n")
cat("Budget curve: 1M", round(readRDS(file.path(tmp, "scen_budget_1m.rds"))$avoided, 2), " 2M", round(b$avoided, 2),
    " 3M", round(readRDS(file.path(tmp, "scen_budget_3m.rds"))$avoided, 2), "\n")
