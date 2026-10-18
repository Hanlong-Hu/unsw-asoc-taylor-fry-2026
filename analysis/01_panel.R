# Build beach-month modelling panel (features + counts by outcome)
suppressMessages(library(data.table))
bm  <- fread("beach_monthly.csv"); inc <- fread("incidents.csv", na.strings=c("NA",""))
inc[, month := substr(dte_occurred,4,10)]
inc[, tnum := match(inc_type, c("Mild","CloseCall","Severe"))]
ev <- inc[, .(worst=max(tnum), npeople=.N), by=.(incident_id, beach_nm, month)]
cnt <- ev[, .(n_all=.N, n_mild=sum(worst==1), n_cc=sum(worst==2), n_sev=sum(worst==3), n_people=sum(npeople)), by=.(beach_nm, month)]
p <- merge(bm, cnt, by=c("beach_nm","month"), all.x=TRUE)
for (v in c("n_all","n_mild","n_cc","n_sev","n_people")) set(p, which(is.na(p[[v]])), v, 0L)
p[, `:=`(m = as.integer(substr(month,1,2)), y = as.integer(substr(month,4,7)))]
p[, fy := ifelse(m>=9, y, y-1)]                    # Sep-Aug year, 2016..2025
p[, t  := (y-2016)*12 + m - 9]                      # 0..119
setorder(p, beach_nm, t)
saveRDS(p, "analysis/panel_raw.rds")
cat("rows", nrow(p), " check totals:", sum(p$n_all), sum(p$n_sev), sum(p$n_people), "\n")

# rate per visit by FY and type
r <- p[, .(vis=sum(visitors)/1e6, mild=sum(n_mild)/sum(visitors)*1e5, cc=sum(n_cc)/sum(visitors)*1e5, sev=sum(n_sev)/sum(visitors)*1e6), by=fy]
cat("\nrates per 100k visits (mild, cc) and per 1M (sev), by FY\n"); print(r)
# rate per visit by calendar month
cat("\nrate by calendar month per 100k visits\n"); print(p[, .(vis=sum(visitors)/1e6, all=sum(n_all)/sum(visitors)*1e5, sev=sum(n_sev)/sum(visitors)*1e6), by=m][order(m)])
# concentration
b <- p[, .(vis=sum(visitors), all=sum(n_all), sev=sum(n_sev), lg=mean(lg_hrs), pat=mean(patrolled), dr=mean(drone_hrs>0)), by=.(beach_nm,postcode)]
b[, `:=`(rate=all/vis*1e5, sevrate=sev/vis*1e6)]
cat("\ntop 12 beaches by severe count\n"); print(b[order(-sev)][1:12])
cat("\nshare of severe in top 10 beaches:", sum(b[order(-sev)][1:10]$sev)/sum(b$sev), "\n")
cat("\nrate by patrolled\n"); print(p[, .(all=sum(n_all)/sum(visitors)*1e5, sev=sum(n_sev)/sum(visitors)*1e6, n=.N), by=patrolled])
cat("\nrate by drone>0\n"); print(p[, .(all=sum(n_all)/sum(visitors)*1e5, sev=sum(n_sev)/sum(visitors)*1e6, n=.N), by=.(d=drone_hrs>0)])
cat("\nnumeric correlations with log rate (n_all/visitors), beach-months with n>=0\n")
num <- c("air_temp_hi","swell_avg_m","swell_max_m","wind_days","water_temp","rain_mm","turbidity","tourist_ratio","lg_hrs","drone_hrs","campaign_idx","first_aid_cap","equip_rating","n_bins","icecream_visits","surfer_prop","n_rips","shore_len_m","visitors")
cr <- sapply(num, function(v) c(all=cor(p[[v]], p$n_all/p$visitors, method="spearman"), sev=cor(p[[v]], p$n_sev/p$visitors, method="spearman"), vis=cor(p[[v]], log(p$visitors))))
print(round(t(cr),3))
