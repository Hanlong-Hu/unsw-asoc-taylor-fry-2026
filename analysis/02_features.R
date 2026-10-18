# Feature engineering on the beach-month panel
suppressMessages(library(data.table))
p <- readRDS("analysis/panel_raw.rds")
p[, `:=`(
  lvis      = log(visitors),
  vis_per_m = visitors / shore_len_m,                 # crowding
  lvis_pm   = log(visitors / shore_len_m),
  rip_dens  = n_rips / (shore_len_m/1000),            # rips per km
  swell_gap = swell_max_m - swell_avg_m,              # surge/variability
  big_swell = as.integer(swell_max_m >= 2.5),
  lg_pv     = lg_hrs / visitors * 1000,               # guard-hrs per 1,000 visits
  lg_pm     = lg_hrs / (shore_len_m/1000),            # guard-hrs per km
  l_lg      = log1p(lg_hrs),
  drone_on  = as.integer(drone_hrs > 0),
  l_drone   = log1p(drone_hrs),
  camp_on   = as.integer(campaign_idx > 0),
  mh        = c(L=0,M=1,H=2)[marine_health],          # ordinal marine health
  summer    = as.integer(m %in% c(12,1,2)),
  winter    = as.integer(m %in% c(6,7,8)),
  covid     = as.integer(t >= (2019-2016)*12 + 9 - 9 + 0 & fy %in% 2019:2020),  # FY2019-20 dip (assumption; tested below)
  yrs       = (fy - 2016)
)]
p[, beach := factor(beach_nm)]
p[, pc    := factor(postcode)]
p[, mfac  := factor(m)]
# calendar harmonics (compact alternative to month dummies)
p[, `:=`(s1=sin(2*pi*m/12), c1=cos(2*pi*m/12), s2=sin(4*pi*m/12), c2=cos(4*pi*m/12))]
# beach-level aggregates (static risk profile; computed from TRAIN only inside models if used as target-encoding)
saveRDS(p, "analysis/panel_feat.rds")
cat("features:", ncol(p), "cols\n")
# quick diagnostics on key engineered features
cat("\nlog(visitors) range:", range(p$lvis), "\n")
cat("corr lvis vs n_bins:", cor(p$lvis, log(p$n_bins)), "  vs icecream:", cor(p$lvis, p$icecream_visits), "  vs lg_hrs:", cor(p$lvis, p$l_lg), "\n")
cat("corr air_temp vs water_temp:", cor(p$air_temp_hi,p$water_temp), "  swell_avg vs swell_max:", cor(p$swell_avg_m,p$swell_max_m), "\n")
cat("corr icecream vs air_temp:", cor(p$icecream_visits,p$air_temp_hi), "\n")
cat("patrolled beaches by month share:\n"); print(round(p[, mean(patrolled), by=m][order(m)]$V1,2))
cat("lg_hrs>0 but tiny? quantiles of lg_hrs when patrolled:\n"); print(quantile(p[patrolled==1]$lg_hrs, c(.01,.1,.5,.9,.99)))
cat("first_aid_cap by FY (mean):\n"); print(round(p[, mean(first_aid_cap), by=fy][order(fy)]$V1,1))
cat("equip_rating by FY (mean):\n"); print(round(p[, mean(equip_rating), by=fy][order(fy)]$V1,1))
