# Task 1 modelling notes (initial pass)

Scripts (run in order, R): `00_eda.R` → `01_panel.R` → `02_features.R` → `03_models.R` → `04_sev.R` → `05_incident_level.R`.
Panel: 9,600 beach-months; 32,459 incidents (28,997 Mild / 3,242 CloseCall / 220 Severe by worst outcome).

## Validation criteria
1. Primary: rolling-origin (expanding window, test = one Sep–Aug year) out-of-sample NB/Poisson negative log-likelihood.
2. Secondary: Poisson deviance, predicted/actual total (calibration), AIC/BIC (in-sample, parsimony).
3. Severe only: top-10 beach capture (share of next year's severe incidents in the 10 beaches ranked highest by the model; random = 12.5%).

## Findings that drive feature choices
- Exposure is sub-linear: log(visitors) coefficient ~0.88–0.95, not 1. Winter incident rate per visit is ~2x summer. Use log(visitors) as a covariate, not a fixed offset.
- Patrol is seasonal (80% of beach-months Sep–Apr, 12% May–Aug) and confounded with season. Keep month and patrol together.
- Lifeguards/drones/campaign do not reduce total incident counts much (reporting/detection effect) but lower severity: P(severe | incident) falls with n_lifeguards (0.98% → 0.36%) and drones (0.67% → 0.34%).
- Beach fixed effects win for Mild/total; static characteristics win for CloseCall (fixed effects overfit); Severe is too sparse for either.
- icecream_visits and n_bins are proxies for temperature and beach size (corr 0.72 / 0.92 with temperature / log visitors); no added predictive value. Drop.
- swell_max and swell_avg corr 0.96; air and water temp corr 0.79. Keep one of each.
- Visitor volumes dropped in FY2019–21; Severe per visit also fell after FY2018.

## Caveats
- response_min for Severe is ~750 min (bodies found late); do not use as a predictor (post-outcome).
- Safety inputs are probably allocated where risk is high (reverse causality); effect sizes are associational.
- Forecasting needs future visitors/weather/safety levels; these are assumptions.
