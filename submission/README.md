# Taylor Fry Case Competition 2026: model files

These are the R files behind our slide pack. Task 1 forecasts next year's beach safety incidents (`part1/`). Task 2 allocates the extra $2M a year to minimise severe incidents (`part2/`).

**To see the results without running anything**, open the rendered reports in a browser:

- `part1/05_validation.html`: model comparison and choice (Task 1)
- `part1/06_forecast.html`: next year's (FY2027) incidents by severity, beach and month (Task 1)
- `part2/optimise.html`: funding allocation, costs and uncertainty (Task 2)

Key outputs are also included as CSVs:

- `part1/forecast_fy2027.csv`: expected FY2027 incidents by beach, month and severity
- `part2/optimal_allocation_by_beach.csv`: recommended spend by beach and initiative
- `part2/optimal_allocation_by_postcode.csv`: campaign spend by postcode

## Running the code

1. Put the three provided datasets in `part1/`: `beach_monthly.csv`, `incidents.csv`, `pricing.csv`. They aren't included here because you already have them.
2. Open R in this folder. Every path is relative to this folder, and each file finds it automatically (via `rprojroot`), so you can knit from anywhere.
3. Knit or run the files in this order. Each saves an `.rds` that the next one reads.

| Step | File | What it does | Saves |
|---|---|---|---|
| 1 | `part1/01_data_prep.Rmd` | Builds the beach-month panel with incident counts by severity | `panel.rds` |
| 2 | `part1/02_eda.Rmd` | Exploratory look at the counts | – |
| 3 | `part1/03_features.Rmd` | Builds and chooses the predictors | `panel_f.rds` |
| 4 | `part1/04_baseline_models.Rmd` | Poisson and negative binomial GLMs | – |
| 5 | `part1/05_validation.Rmd` | Rolling-origin out-of-sample comparison; picks a model per severity | `chosen_specs.rds` |
| 6 | `part1/06_forecast.Rmd` | FY2027 forecast with simulated uncertainty ranges | `forecast_fy2027.rds` / `.csv` |
| 7 | `part2/optimise.Rmd` | Mixed-integer optimisation of the $2M across beaches and initiatives, using the step 6 forecast | `optimal_allocation_*.csv` |

### Robustness checks (optional, `part2/robustness/`)

These produce the numbers behind the appendix sensitivity charts. Run them from this folder after step 7.

- `Rscript part2/robustness/robust_a.R`: stability of the safety-measure effects across training windows and model variants
- `Rscript part2/robustness/scenario.R <name>`: re-runs the optimiser under a different budget or set of effect sizes, set with env vars `BUDGET` (e.g. `1e6`) and `B_OVERRIDE` (e.g. `"log_drone=-0.13,flags=0"`). Saves `part2/robustness/out/scen_<name>.rds`.
- `Rscript part2/robustness/robust_c.R`: compares the base plan with the plan re-optimised under each scenario. It needs the `base`, `drone_half`, `beach_fe`, `robust_only`, `pessimistic`, `budget_1m` and `budget_3m` scenarios from `scenario.R` first.
- `Rscript part2/robustness/chart_data.R`: prints the figures used in the deck's charts and tables

## Software

R 4.x with these packages: `dplyr`, `tidyr`, `ggplot2`, `lubridate`, `MASS`, `knitr`, `rmarkdown`, `rprojroot`, `xgboost` (step 5, as a benchmark only), and for step 7 `ompr`, `ompr.roi`, `ROI`, `highs`.

```r
install.packages(c("dplyr", "tidyr", "ggplot2", "lubridate", "MASS", "knitr", "rmarkdown", "rprojroot",
                   "xgboost", "ompr", "ompr.roi", "ROI", "highs"))
```

Step 6 simulates 5,000 years and step 7 gives the solver up to 10 minutes. Random seeds are fixed, so the results are reproducible.
