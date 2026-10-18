suppressMessages({library(data.table)})
bm <- fread("beach_monthly.csv"); inc <- fread("incidents.csv", na.strings=c("NA",""))
cat("== incidents ==\n"); print(summary(inc))
for (v in c("inc_type","inc_cause","swim_level","local_ind","drone_present","sex")) {cat("\n",v,"\n"); print(table(inc[[v]],useNA="ifany"))}
# incident level: one row per incident, worst outcome
inc[, mon := substr(dte_occurred,4,10)]
ev <- inc[, .(worst = c("Mild","CloseCall","Severe")[max(match(inc_type,c("Mild","CloseCall","Severe")))],
              npeople=.N, beach_nm=beach_nm[1], mon=mon[1], n_lifeguards=n_lifeguards[1], drone=drone_present[1], resp=response_min[1], hr=inc_hour[1]), by=incident_id]
cat("\nevents by worst outcome\n"); print(table(ev$worst))
cat("\npeople by type\n"); print(table(inc$inc_type))
# by year (Sep-Aug)
ev[, yr := { m<-as.integer(substr(mon,1,2)); y<-as.integer(substr(mon,4,7)); ifelse(m>=9,y,y-1)}]
inc[, yr := { m<-as.integer(substr(mon,1,2)); y<-as.integer(substr(mon,4,7)); ifelse(m>=9,y,y-1)}]
cat("\npeople by FY x type\n"); print(dcast(inc[, .N, by=.(yr,inc_type)], yr~inc_type, value.var="N"))
# beach-month panel
bm[, yr := { m<-as.integer(substr(month,1,2)); y<-as.integer(substr(month,4,7)); ifelse(m>=9,y,y-1)}]
cat("\nvisitors by FY\n"); print(bm[, .(vis=sum(visitors), lg=sum(lg_hrs), drone=sum(drone_hrs)), by=yr])
cat("\nstatic-ness check\n")
for (v in c("pa_system","flags","equip_rating","n_bins","rocky","fishing","rockpool","shore_len_m","n_rips","postcode")) cat(v, ": beaches varying =", bm[, uniqueN(get(v)), by=beach_nm][V1>1,.N], "\n")
cat("\nNA counts\n"); print(colSums(is.na(bm)))
print(summary(bm))
cat("\nbeach-months: patrolled share", mean(bm$patrolled), " drone>0 share", mean(bm$drone_hrs>0), " campaign>0", mean(bm$campaign_idx>0),"\n")
cat("beaches never patrolled:", bm[, .(p=mean(patrolled)), by=beach_nm][p==0,.N], " always:", bm[, .(p=mean(patrolled)), by=beach_nm][p==1,.N], "\n")
cat("beaches ever drone:", bm[, .(d=max(drone_hrs)), by=beach_nm][d>0,.N], "\n")
# incident-beach-month dispersion
cnt <- ev[, .N, by=.(beach_nm,mon)]
p <- merge(bm[, .(beach_nm, mon=month)], cnt, by=c("beach_nm","mon"), all.x=TRUE); p[is.na(N), N:=0]
cat("\nbeach-month event counts: mean", mean(p$N), "var", var(p$N), " zero share", mean(p$N==0), "\n"); print(table(pmin(p$N,10)))
sv <- ev[worst=="Severe", .N, by=.(beach_nm,mon)]
ps <- merge(bm[, .(beach_nm, mon=month)], sv, by=c("beach_nm","mon"), all.x=TRUE); ps[is.na(N), N:=0]
cat("\nsevere beach-month: mean", mean(ps$N), "zero share", mean(ps$N==0), "\n"); print(table(ps$N))
# time-of-day, month seasonality
cat("\nby calendar month (events)\n"); print(ev[, .N, by=.(m=as.integer(substr(mon,1,2)))][order(m)])
cat("\nsevere by cause\n"); print(table(inc$inc_cause, inc$inc_type))
cat("\nsevere by swim_level\n"); print(table(inc$swim_level, inc$inc_type, useNA="ifany"))
cat("\nbeach check: incident beaches not in bm:", setdiff(unique(inc$beach_nm), unique(bm$beach_nm)), "\n")
cat("\nresponse_min by lifeguards>0 and type\n"); print(ev[, .(mean(resp,na.rm=T), sum(is.na(resp))), by=.(lg=n_lifeguards>0, worst)])
