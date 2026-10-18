# STEP 1: Understand the data and build the table we will model
# Goal: end with ONE table where each row is a beach in a month,
#       with the number of Mild / CloseCall / Severe incidents in that row.
# Run from the project folder:  Rscript analysis/step1_data_and_counts.R

library(dplyr)

# ---- 1. Load the two main files ------------------------------------------
beach     <- read.csv("beach_monthly.csv")   # one row per beach per month
incidents <- read.csv("incidents.csv")       # one row per PERSON in an incident

cat("beach_monthly rows:", nrow(beach), "\n")   # expect 80 beaches x 120 months = 9600
cat("incidents rows:    ", nrow(incidents), "\n")  # 33,941 people

# ---- 2. Why we cannot just count rows in incidents -----------------------
# Some incidents involve 2 or 3 people and share an incident_id.
# We want to count INCIDENTS (events), so we collapse people to incidents.
cat("\nUnique incidents:", n_distinct(incidents$incident_id), "\n")   # 32,459

# ---- 3. Give each incident ONE severity ----------------------------------
# Severity is recorded per person, ordered Mild < CloseCall < Severe.
# Rule: an incident takes the WORST outcome of anyone involved.
incidents <- incidents %>%
  mutate(severity_rank = case_when(inc_type == "Mild"      ~ 1,
                                   inc_type == "CloseCall" ~ 2,
                                   inc_type == "Severe"    ~ 3))

one_row_per_incident <- incidents %>%
  mutate(month = substr(dte_occurred, 4, 10)) %>%   # "01/09/2016" -> "09/2016"
  group_by(incident_id, beach_nm, month) %>%
  summarise(worst = max(severity_rank), .groups = "drop") %>%
  mutate(severity = c("Mild", "CloseCall", "Severe")[worst])

cat("\nIncidents by severity (worst person):\n")
print(table(one_row_per_incident$severity))

# ---- 4. Count incidents per beach-month, by severity ---------------------
counts <- one_row_per_incident %>%
  group_by(beach_nm, month) %>%
  summarise(n_all  = n(),
            n_mild = sum(severity == "Mild"),
            n_cc   = sum(severity == "CloseCall"),
            n_sev  = sum(severity == "Severe"),
            .groups = "drop")

# ---- 5. Join onto beach_monthly and fill the zeros -----------------------
# Beach-months with no incident do not appear in `counts`, so they join as NA.
# The data dictionary says these must be ZERO, not missing.
panel <- beach %>%
  left_join(counts, by = c("beach_nm", "month")) %>%
  mutate(across(c(n_all, n_mild, n_cc, n_sev), ~ coalesce(.x, 0L)))

# ---- 6. Sanity checks (always check a join did not lose or invent rows) --
cat("\nPanel rows:", nrow(panel), "(should be 9600)\n")
cat("Total incidents in panel:", sum(panel$n_all), "(should be 32459)\n")
cat("Total severe in panel:   ", sum(panel$n_sev), "(should be 220)\n")

# ---- 7. How are the counts distributed? ----------------------------------
cat("\nShare of beach-months with zero incidents:",
    round(mean(panel$n_all == 0), 3), "\n")
cat("Mean incidents per beach-month:", round(mean(panel$n_all), 2),
    "  Variance:", round(var(panel$n_all), 1), "\n")
cat("Share of beach-months with zero SEVERE incidents:",
    round(mean(panel$n_sev == 0), 3), "\n")

# ---- 8. Create the Sep-Aug "year" used throughout ------------------------
# The data runs Sep 2016 - Aug 2026, so we group by a Sep-Aug year (call it fy).
panel <- panel %>%
  mutate(cal_month = as.integer(substr(month, 1, 2)),
         cal_year  = as.integer(substr(month, 4, 7)),
         fy        = ifelse(cal_month >= 9, cal_year, cal_year - 1))

cat("\nIncidents by Sep-Aug year and severity:\n")
print(panel %>% group_by(fy) %>%
        summarise(Mild = sum(n_mild), CloseCall = sum(n_cc), Severe = sum(n_sev)))

saveRDS(panel, "analysis/panel_step1.rds")   # saved for the next step
