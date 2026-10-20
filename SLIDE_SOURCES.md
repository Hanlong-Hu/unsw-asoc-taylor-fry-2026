# Slide sources

Where every figure and claim in the deck comes from. Deck: https://claude.ai/artifact/S7p3VqBKXfcksbJPHMATn9 (slide files in `presentation/deck_artifact/project/slides/<id>.html`).

Paths are relative to the project root. Line numbers are as of commit on 2026-10-20. Data files (`part1/*.csv`, `*.rds`) are gitignored; run the Part 1 notebooks in order to recreate them.

**How to read the "Check" column**
- **Notebook**: the figure is printed or stated in that notebook.
- **Recomputed**: re-derived from the data on 2026-10-20 while building this map (value shown).
- **Placeholder**: still a bracketed gap on the slide; the source to fill it from is given.
- **Draft**: plain-language wording or plan written for the deck, not a computed result.

---

## Opening

### 1 · `cover` — Spending $2M where it prevents the most severe beach incidents
| Claim | Source | Check |
|---|---|---|
| $2M a year, minimise severe incidents | `context.md:22-23` (Task 2) | Brief |
| "Mostly drones, plus winter patrols, campaigns and rip flags … about 12.5 a year" | `part2/optimise.Rmd` §5 Results (`:257`); `presentation/optimise_results.md:7-22` | Notebook |
| Date: October 2026 | `timeline_plan.md:3` (main checkout, gitignored): slides due Thu 22 Oct, heats from 29 Oct | Planning note |
| Team name, members | — (not recorded anywhere in the project) | Placeholder |

### 2 · `exec` — Severe risk is concentrated, so $2M can target it
| Claim | Source | Check |
|---|---|---|
| ≈ 21 severe incidents in FY2027 | `part1/06_forecast.Rmd:152` (§4 Predict) | Notebook (21.4) |
| (15–33), 90% range | `part1/06_forecast.Rmd:269` (§5 Uncertainty, 5,000 simulated years) | Notebook |
| ~50% at the top 10 beaches | `part1/06_forecast.Rmd:206` (§4 Where) | Notebook |
| Winter visit 4–7× riskier than summer | `part1/06_forecast.Rmd:177` (§4 When) | Notebook |
| ≈ 12.5 (11–16) fewer a year | `part2/optimise.Rmd` §5 (`:257`) and §6 Uncertainty (`:359`) | Notebook |
| $1.16M drones, $392k patrols, $330k campaigns, $115k flags | `part2/optimise.Rmd` §5, `cost` vector; `presentation/optimise_results.md:14-22` | Notebook |

### 3 · `brief` — Goal: fewest severe incidents for $2M a year
| Claim | Source | Check |
|---|---|---|
| Task 1 and Task 2 wording | `context.md:18-25` | Brief |
| Data: 10 years Sep 2016 – Aug 2026, 80 beaches, price list, no outside data | `context.md:26-31`, `context.md` "Tips from the brief" | Brief |

## Task 1 · Forecast

### 4 · `div1` — Forecasting next year's incidents
Divider, no figures.

### 5 · `pipeline` — Turning raw records into a table we can forecast
| Claim | Source | Check |
|---|---|---|
| 33,941 people in the incident records | `part1/01_data_prep.Rmd` §1 Load (`:23`); `presentation_notes.md:12` | Recomputed (`nrow(incidents.csv)` = 33,941) |
| 32,459 distinct incidents | `part1/01_data_prep.Rmd` §3 Collapse people to incidents (`:42`); `presentation_notes.md:13` | Notebook |
| 80 beaches × 120 months = 9,600 beach-months | `part1/01_data_prep.Rmd` §5–6 (`:73`, `:86` sanity checks) | Notebook |
| Counts by severity per row | `part1/01_data_prep.Rmd` §4 (`:60`) | Notebook |

### 6 · `season` — Summer has the crowds; winter has the risk
| Claim | Source | Check |
|---|---|---|
| June visit ~5–6× riskier than January | `presentation_notes.md:60` (02 EDA) | Recomputed: 0.299 vs 0.054 severe per 100k visits = **5.5×** |
| ~80% of beach-months patrolled Sep–Apr vs ~12% May–Aug | `part1/04_baseline_models.Rmd:121` | Recomputed: 0.80 vs 0.12 |
| Chart: visitors a year and severe per 100k visits by month (two panels, one axis each) | `part2/robustness/chart_data.R` "Slide 6"; `panel_f.rds`, 10 years | Recomputed (Jan 4.8M visitors; Jun 0.30 vs Jan 0.05 per 100k) |

### 7 · `model` — Six inputs, one simple model per severity
| Claim | Source | Check |
|---|---|---|
| Inputs and transforms (visitors offset, `log1p` hours, month, rips per km, beach traits) | `part1/03_features.Rmd` §2 Build the features (`:61`, `log1p` at `:73-75`); `presentation_notes.md` §03 (`:91`) | Notebook |
| Negative binomial, one per severity, visitors offset | `part1/04_baseline_models.Rmd` §3 (`:60`); `part1/06_forecast.Rmd:39-42` | Notebook |
| Severe and close calls use beach traits; mild uses beach effects | `part1/05_validation.Rmd` §6 Decision (`:406`, saved at `:439`) | Notebook |
| "Why" column wording | — | Draft |

### 8 · `validation` — Tested on years it hadn't seen, and it held up
| Claim | Source | Check |
|---|---|---|
| Rolling-origin test | `part1/05_validation.Rmd` §4 Rolling origin (`:206`) | Notebook |
| XGBoost "no clear improvement: slightly better log score, 12% too high on severe totals" | `part1/05_validation.Rmd` §5 (`:271`), severe verdict `:369-371`, decision `:401`; table in `part1/05_validation.html` (severe log score 0.0878 GLM vs 0.0854 XGB; ratio 1.12) | Notebook. **Corrected 2026-10-20**: the slide said "did not beat it", which overstated `:369` ("no clear winner") |
| 5 test years (FY2022–26), log score | `part1/05_validation.Rmd` §4 (`:206`) and §2 Scoring functions (`:66`) | Notebook |
| Chart: forecast, 90% range and actual per test year; every actual inside the range | `part2/robustness/chart_data.R` "Slide 8 / A2" | Recomputed (severe 5 of 5 inside; FY2026: 26 vs 19.2, range 13–30) |

### 9 · `forecast` — Expect about 21 severe incidents in FY2027
| Claim | Source | Check |
|---|---|---|
| ~3,600 mild, ~316 close calls, ≈ 21 severe | `part1/06_forecast.Rmd:152` | Notebook |
| (15–33), 90% range | `part1/06_forecast.Rmd:269` | Notebook |
| FY2027 = Sep 2026 – Aug 2027; safety at FY2026 levels | `part1/06_forecast.Rmd:17`, `:56`; `presentation_notes.md` §03 "Financial year" | Notebook |

### 10 · `wherewhen` — Severe risk clusters at a few beaches in winter
| Claim | Source | Check |
|---|---|---|
| North Wollongong top for severe, about 2 a year | `part1/06_forecast.Rmd:211` | Recomputed: 2.00 |
| Seven Mile Beach about 6× Bondi's severe risk per visit | `part1/06_forecast.Rmd:209` (per-visit risk in top-10 table) | Recomputed: FY2027 forecast 3.05 vs 0.51 per million visits = **6.0×** (history: 7.7×). **Corrected 2026-10-20**: the slide previously said 5×, taken from an early design note; 5× holds against North Wollongong and Byron, not Bondi |
| May–Aug: ~44% of the year's severe risk | `part1/06_forecast.Rmd:177` | Notebook (9.5 of 21.4) |
| Top 10 beaches ≈ half of severe risk (speaker notes) | `part1/06_forecast.Rmd:206` | Notebook |
| Heatmap: top 20 beaches × month, expected severe, with yearly totals | `part2/robustness/chart_data.R` "Slide 10" (from `forecast_fy2027.rds`); notebook version (close calls + severe) at `part1/06_forecast.Rmd:195` | Recomputed |

### 11 · `drivers` — Lifeguards and drones go with lower severe risk
| Claim | Source | Check |
|---|---|---|
| Raise risk: swell, rips per km, tourists | Severe model `final$sev` refitted in `part1/06_forecast.Rmd:42` (swell +0.69, rips +0.20, tourist share +4.17) | Notebook object; printed in `presentation/optimise_results.md` run log |
| Each extra metre of swell roughly doubles severe risk (speaker notes) | `part1/06_forecast.Rmd:61` | Notebook (exp(0.69) = 2.0) |
| Lower risk: lifeguard hours, drone hours, campaigns, flags | `part2/optimise.Rmd:53` (prints the lever coefficients) | Notebook |
| First aid and PA show no effect (speaker notes) | `part2/optimise.Rmd:53-58` | Notebook |
| Association, not proof | `part1/06_forecast.Rmd:295`; robustness `presentation_notes.md:221-247` | Notebook |
| Rate-ratio dot chart with 95% ranges (swell ×1.99, drones 0→100 hrs ×0.30, first aid ×1.03 …) | `part2/robustness/chart_data.R` "Slide 11 / A1" (from `final$sev`) | Recomputed |

## Task 2 · Allocation

### 12 · `div2` — Allocating the extra $2M
Divider, no figures.

### 13 · `recommend` — Spend most of the $2M on drones, then winter patrols
| Claim | Source | Check |
|---|---|---|
| $1.16M drones (27 new, 20,183 hrs), $392k patrols (22 beaches), $330k campaigns (22 postcodes), $115k flags (23 beaches) | `part2/optimise.Rmd` §5 `results` (`:257`) and `allocation` (`:325`); `part2/optimal_allocation_by_beach.csv`; `presentation/optimise_results.md:14-22` | Notebook |
| ≈ 12.5 avoided, 21 → 9, down 58% | `part2/optimise.Rmd` §5 (`:257`) | Notebook (12.48; 21.43 → 8.95) |
| (11–16) a year; 4–16 severe in 9 years of 10 | `part2/optimise.Rmd` §6 Uncertainty (`:359`) | Notebook |
| Beaches gaining most; "+ 61 more" (69 funded) | `part2/optimal_allocation_by_beach.csv` (sorted by `avoided`) | Notebook |
| Drones ≈ 8 of the 12.5 (speaker notes) | `presentation/optimise_results.md:16-21` ("Avoided on its own") | Notebook |

### 14 · `method` — We put each dollar where it avoids the most
| Claim | Source | Check |
|---|---|---|
| Four steps: baseline, price, value, optimise | `part2/optimise.Rmd` §1–4 (`:27`, `:71`, `:102`, `:173`) | Notebook |
| Spreads across 69 beaches | `part2/optimise.Rmd` `allocation` chunk (`:325`, "Beaches funded") | Notebook |
| New patrols ≥ 97 hours a month | `part2/optimise.Rmd:120` (`MIN_LG`, 5th percentile of patrolled months) | Notebook |

### 15 · `alternatives` — Our mix avoids more severe incidents per dollar
| Claim | Source | Check |
|---|---|---|
| Our plan 12.5, ~$160k per avoided | `part2/optimise.Rmd` §5 (`:257`) | Notebook |
| Education only 2.9, ~$209k ($615k spend) | `part2/optimise.Rmd` §7 Alternatives (`:392`) | Notebook |
| Spread evenly 3.0, ~$656k | `part2/optimise.Rmd` §7 | Notebook |
| Summer-only patrols 0.3, ~$5.6M | `part2/optimise.Rmd` §7 | Notebook |
| Bars: avoided per $1M (6.2, 4.8, 1.5, 0.2) | avoided ÷ spend from `part2/optimise.Rmd` §7 | Derived |
| Stacked $2M bar on slide 13 | `presentation/optimise_results.md:14-22` | Notebook |

### 16 · `implement` — Ready before winter, reviewed after 12 months
| Claim | Source | Check |
|---|---|---|
| 27 drones, 23 flag beaches, 22 campaign postcodes, 22 winter-patrol beaches | `part2/optimal_allocation_by_beach.csv`, `part2/optimal_allocation_by_postcode.csv` | Notebook |
| Campaigns work Nov–Feb | `part2/optimise.Rmd:91` (`SUMMER`) | Model assumption |
| Patrols start in May; half the gain in May–Aug | `part2/optimise.Rmd:344` (`by_month`) | Notebook |
| Quarter-by-quarter actions | — | Draft |
| "The price list gives no lead times" | `part1/pricing.csv` (no lead-time column) | Data |

## Close

### 17 · `assumptions` — What has to hold for this plan to work
| Claim | Source | Check |
|---|---|---|
| Visitors grow 1.9% a year | `part1/06_forecast.Rmd:103`, `:286` | Notebook |
| Weather like the past decade; safety at FY2026 levels | `part1/06_forecast.Rmd:287-288` | Notebook |
| Each initiative works as the Task 1 model says | `part2/optimise.Rmd` §1 (`:27`) | Notebook |
| Association, not causation; severe rare; FY2020–21 dip | `part1/06_forecast.Rmd:295-297` | Notebook |
| 27 new drone beaches have never flown one (≈ 5.4 of 12.5) | `part2/robustness/robust_c.R` C4; `presentation_notes.md:248-252` | Notebook |
| +68% drone hours (20,183 vs 29,566 today) | `part2/robustness/robust_c.R` C4 | Notebook |
| Lifeguard and flag effects least certain | `part2/robustness/robust_a.R` A2; `presentation_notes.md:225-247` (check 2) | Notebook |

### 18 · `conclusion` — Three things to take away
Repeats slide 2: sources as for `exec`. "Approve the $2M plan … 12-month review" is the recommendation (Draft).

## Appendix

### A1 · `a1` — Model specification
| Claim | Source | Check |
|---|---|---|
| NB GLM per severity and its terms | `part1/chosen_specs.rds` (from `part1/05_validation.Rmd:439`); `part1/06_forecast.Rmd:39-42` | Notebook |
| Rate-ratio table | `part2/robustness/chart_data.R` "Slide 11 / A1" | Recomputed |
| Model-choice table (θ = 1.47, offset, log1p, traits vs beach effects, XGBoost) | `part1/06_forecast.Rmd:46`; `presentation_notes.md` §02–03; `part1/05_validation.html` rolling-origin severe table (beach effects 0.34 vs traits 0.088); `part1/05_validation.Rmd:369` | Notebook |

### A2 · `a2` — Validation detail
| Claim | Source | Check |
|---|---|---|
| Rolling origin FY2022–FY2026; log score, MAE, range coverage | `part1/05_validation.Rmd` §2 (`:66`), §4 (`:206`) | Notebook |
| Severe forecast / range / actual table; coverage 5/5 mild, 2/5 close calls, 5/5 severe | `part2/robustness/chart_data.R` "Slide 8 / A2" | Recomputed |
| Log score GLM vs XGBoost and folds won | `part1/05_validation.html`, table "Rolling origin, 5 folds: chosen GLM vs XGBoost" | Notebook |

### A3 · `a3` — Forecast uncertainty (simulation)
| Claim | Source | Check |
|---|---|---|
| 5,000 simulated years; weather, parameter and chance draws; 15–33 | `part1/06_forecast.Rmd` §5 (`:215-251`) | Notebook |
| Histogram and percentile table (mild 3,385–3,832, close calls 280–363, severe 15–33, median 23) | `part2/robustness/chart_data.R` "A3" (from `forecast_fy2027.rds$sims`) | Recomputed |
| Median above point forecast; 1 in 3 chance of 26+ | `part1/06_forecast.Rmd:225`, `:269` | Notebook |

### A4 · `a4` — Optimisation formulation
| Claim | Source | Check |
|---|---|---|
| Variables, objective, constraints, ≥ 97-hr patrols | `part2/optimise.Rmd` §3–4 (`:102`, `:173`) | Notebook |
| HiGHS, within 0.6% of optimal | `part2/optimise.Rmd` `solve` chunk (`:226`) | Notebook |
| Budget curve $0–3M (8.5, 10.6, 11.8, 12.5, 13.0, 13.2) | `part2/robustness/scenario.R` runs `budget_0.5m` … `budget_3m` (`BUDGET` env var) | Notebook |

### A5 · `a5` — Pricing inputs
| Claim | Source | Check |
|---|---|---|
| Initiative price list | `part1/pricing.csv`; used in `part2/optimise.Rmd` §2 (`:71`) | Data |
| Conversion to hours, costs charged in full (`AMORT = 1`), 3-year drone life | `part2/optimise.Rmd` §2 (`FTE_HRS`, `DRONE_CAP`, `AMORT`); `part1/pricing.csv` notes column | Notebook |

### A6 · `a6` — The plan holds under every check: 8–13 fewer severe incidents
| Claim | Source | Check |
|---|---|---|
| 12.5 / 11.3 / 10.3 / 10.2 / 8.4 / 8.1 and the "vs best plan" shares | `part2/robustness/robust_c.R` C1–C2 (uses `scenario.R` runs `base`, `beach_fe`, `robust_only`, `drone_half`, `pessimistic`) | Notebook |
| Drones and campaigns pass every check; lifeguards and flags only between beaches | `part2/robustness/robust_a.R` A1–A5; `presentation_notes.md:221-247` | Notebook |
| 128 expected without drones vs 56 actual (speaker notes) | `part2/robustness/robust_c.R` C3 | Notebook |

---

**To re-run everything:** `part1/01…06` in order, then `part2/optimise.Rmd`, then `Rscript part2/robustness/scenario.R <name>` (with `BUDGET` / `B_OVERRIDE` as in `presentation_notes.md` §08) followed by `robust_a.R` and `robust_c.R`.
