suppressMessages({library(data.table); library(MASS)})
inc <- fread("incidents.csv", na.strings=c("NA","")); p <- readRDS("analysis/panel_feat.rds")
inc[, month := substr(dte_occurred,4,10)]
d <- merge(inc, p[, .(beach_nm, month, fy, m, visitors, lg_hrs, drone_hrs, patrolled, first_aid_cap, flags, pa_system, equip_rating, swell_max_m, water_temp, wind_days, tourist_ratio, n_rips, campaign_idx, rocky)], by=c("beach_nm","month"))
d[, sev := as.integer(inc_type=="Severe")]; d[, cc := as.integer(inc_type=="CloseCall")]
d[, `:=`(lg=pmin(n_lifeguards,5), dr=as.integer(drone_present=="Y"), child=as.integer(age<18), senior=as.integer(age>=65), night=as.integer(inc_hour<7 | inc_hour>=19))]
cat("P(severe) / P(CC) by n_lifeguards\n"); print(d[, .(n=.N, sev=mean(sev)*100, cc=mean(cc)*100), by=n_lifeguards][order(n_lifeguards)])
cat("\nby drone_present\n"); print(d[, .(n=.N, sev=mean(sev)*100, cc=mean(cc)*100), by=drone_present])
cat("\nby swim_level\n"); print(d[, .(n=.N, sev=mean(sev)*100, cc=mean(cc)*100), by=swim_level])
cat("\nby age band\n"); print(d[, .(n=.N, sev=mean(sev)*100, cc=mean(cc)*100), by=.(ageb=cut(age,c(0,5,12,17,29,44,64,200)))][order(ageb)])
cat("\nby alone / local / sex / surfer\n"); for (v in c("alone","local_ind","sex","surfer")) print(d[, .(n=.N, sev=mean(sev)*100, cc=mean(cc)*100), by=c(v)])
cat("\nby hour band\n"); print(d[, .(n=.N, sev=mean(sev)*100), by=.(hb=cut(inc_hour,c(-1,5,8,11,14,17,20,23)))][order(hb)])
cat("\nresponse_min quantiles by type\n"); print(d[, as.list(quantile(response_min, c(.1,.5,.9), na.rm=TRUE)), by=inc_type])
cat("\nby cause\n"); print(d[, .(n=.N, sev=mean(sev)*100, cc=mean(cc)*100), by=inc_cause])
cat("\nby flags / pa\n"); print(d[, .(n=.N, sev=mean(sev)*100, cc=mean(cc)*100), by=flags]); print(d[, .(n=.N, sev=mean(sev)*100, cc=mean(cc)*100), by=pa_system])
# multi-person incidents: severity?
cat("\nsevere by group size\n"); print(d[, .(n=.N, sev=mean(sev)*100), by=.N, ][0]); 
gs <- d[, .(gs=.N), by=incident_id]; d <- merge(d, gs, by="incident_id"); print(d[, .(n=.N, sev=mean(sev)*100, cc=mean(cc)*100), by=gs])
# logistic for severe given incident (person-level), then CV by FY
f_sev <- sev ~ lg + dr + swim_level + child + senior + alone + night + sex + local_ind + swell_max_m + water_temp + first_aid_cap + flags + pa_system + equip_rating + n_rips
m <- glm(f_sev, binomial, d); print(round(summary(m)$coefficients[,c(1,4)],3))
f_cc <- cc ~ lg + dr + swim_level + child + senior + alone + night + sex + local_ind + swell_max_m + water_temp + first_aid_cap + flags + pa_system + equip_rating + n_rips
m2 <- glm(f_cc, binomial, d); print(round(summary(m2)$coefficients[,c(1,4)],3))
