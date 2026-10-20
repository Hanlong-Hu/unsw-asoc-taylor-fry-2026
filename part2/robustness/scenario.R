# Usage: Rscript scenario.R <name>   with env BUDGET and B_OVERRIDE ("log_drone=-0.13,flags=0")
setwd(rprojroot::find_root(rprojroot::has_dir("part1")))
name <- commandArgs(TRUE)[1]
tmp <- "part2/robustness/out"; dir.create(tmp, showWarnings = FALSE)
knitr::purl("part2/optimise.Rmd", output = file.path(tmp, "opt_base.R"), quiet = TRUE)
src <- readLines(file.path(tmp, "opt_base.R"))
src <- src[seq_len(grep("^## ----unc", src) - 1)]                    # stop before the simulation
src <- src[!grepl("write.csv", src)]                                 # never overwrite the real outputs
src <- sub("^BUDGET +<- 2e6", "BUDGET <- as.numeric(Sys.getenv('BUDGET', '2e6'))", src)
i <- grep("^b +<- coef\\(glm_fit\\)", src)
src <- append(src, "ov <- Sys.getenv('B_OVERRIDE'); if (nzchar(ov)) for (p in strsplit(strsplit(ov, ',')[[1]], '=')) b[[p[1]]] <- as.numeric(p[2])", i)
writeLines(src, f <- file.path(tmp, paste0("opt_", name, ".R")))
invisible(capture.output(suppressWarnings(suppressMessages(source(f)))))
saveRDS(list(name = name, cost = cost, baseline = baseline_total, after = sum(win$mu_new), avoided = avoided,
             lg_add = lg_add, dh_v = dh_v, flag_v = flag_v, camp_v = camp_v, fte_v = fte_v, ydr_v = ydr_v,
             gap = hs$info$mip_gap, status = hs$status_message, n_beach = nrow(by_beach),
             winter_lg_beaches = sum(by_beach$winter_lg_hrs > 0), b = b),
        file.path(tmp, paste0("scen_", name, ".rds")))
cat(sprintf("%-12s %s gap %.3f | avoided %.2f (%.1f -> %.1f) | ", name, hs$status_message, hs$info$mip_gap, avoided, baseline_total, sum(win$mu_new)))
cat(paste(names(cost), round(cost / 1e3), sep = "=", collapse = " "), "($k)\n")
