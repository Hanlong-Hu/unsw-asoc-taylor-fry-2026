# Han's meeting notes: Task 1.1 (predicting incidents)

**Status:** steps 01–04 done (data, EDA, features, models). Steps 05 (validation) and 06 (forecast) still to do. No forecast number yet.

## 1. The data I built
- `incidents.csv` has one row per *person*. I collapsed to one row per *incident*, taking the worst severity among the people involved: 32,459 incidents (28,997 mild / 3,242 close call / 220 severe).
- Joined to `beach_monthly.csv` → **9,600 rows = 80 beaches × 120 months**, with counts by severity next to the beach conditions. Months with no incidents are zeros.
- Training data so far: Sep 2016 – Aug 2025. Held out for testing: Sep 2025 – Aug 2026.

## 2. What the EDA showed (and why it shapes the model)
| Finding | What it means |
|---|---|
| Counts are **overdispersed**: mean 3.3, variance 45 per beach-month | Poisson assumes variance = mean, so it would be far too confident. Use **negative binomial** (NB), which adds a spread parameter. |
| Many zeros for severe incidents (only ~220 events) | Severe counts are too sparse to model reliably on their own. |
| Incidents rise with visitors, but **less than one-for-one** (slope ~0.9) | More visitors means more incidents, with a bit less than proportional growth. |
| **Seasonality:** per-visitor risk is higher in winter than summer | Winter has fewer people but they are riskier (rougher seas, fewer patrols). Raw counts hide this; per-visit rates show it. |
| **FY2020–21 dip:** incidents per 100k visits fell from ~13.7 to ~10.7, recovering to ~12–13 | Unexplained in the data. I added a flag for it and will list it as a limitation. |

## 3. How the model works (explain this carefully)
- It's a **negative binomial regression**: `log(expected incidents) = intercept + b1·x1 + b2·x2 + …`.
- **Reading a coefficient:** `exp(b)` is a **rate ratio (RR)**, the factor the expected count is multiplied by when `x` goes up by one unit, holding everything else fixed. RR = 1 means no effect, below 1 means fewer incidents, above 1 means more. A 95% interval containing 1 means we can't tell the effect from zero.
- **Visitors enter as an offset** (`offset(log(visitors))`, coefficient fixed at 1), so the model is about **incidents per visitor**. Step 05 will test using `log(visitors)` as a normal term instead, since the data suggest a slope below 1.
- **Why NB over Poisson:** the Poisson overdispersion check gave ~1.9 (deviance/df) and ~2.2 (Pearson); both should be ~1. NB's AIC is 28,664 vs Poisson's 32,392 (lower is better), with spread parameter theta ≈ 3.2.
- **Predictors** (kept small and explainable): month, FY2020–21 flag, conditions (max swell, wind, rain, air temp, marine health), safety (lifeguard hours, drone hours, campaign, first-aid, PA, flags, equipment), beach traits (rips per km, rocky, fishing, rockpool, shore length), visitor mix (surfers, tourists). Near-duplicates dropped (e.g. swell_avg, water temp, turbidity, bins, ice-cream visits).

## 4. Results (total incidents, per visitor)
| Driver | RR | Plain words |
|---|---|---|
| Rips per km | 1.18 | Each extra rip per km: ~18% more incidents. A fixed property of the beach. |
| Max swell (m) | 1.08 | Each extra metre: ~8% more. |
| Tourist ratio | 3.24 | More tourists → more incidents. But the ratio only varies by ~0.17 between typical observations, so a typical rise is ~1.2×, not 3×. |
| Campaign index | 0.42 | Largest protective effect. A full campaign (index up to 0.7, summer only) goes with a big drop. |
| Lifeguard hours (log) | 0.95 | Each extra log-unit of hours: ~5% fewer. 100 → 1,000 hours ≈ 12% fewer. |
| Flags / surfer share | 0.91 / 0.79 | Mildly protective. |
| Drones, PA, first-aid | ~1.0 | No clear effect on total incidents. |

## 5. The key finding: effects differ by severity
| Driver | All | Mild | Close call | **Severe** |
|---|---|---|---|---|
| Lifeguard hours | 0.95 | 0.95 | 0.93 | **0.86** |
| Drone hours | 1.00 | 1.02 | 0.82 | **0.76** |
| Campaign | 0.42 | 0.45 | 0.19 | **0.23** |
| Flags | 0.91 | 0.89 | 0.92 | **0.70** |
| Max swell | 1.08 | 1.01 | 1.51 | **2.09** |

- **Safety measures matter more the more serious the incident.** Drones do nothing for the total, but cut close calls by ~18% and severe by ~24%. This is what Task 2 cares about.
- **Rough seas matter far more for serious incidents** (RR 2.09 for severe vs 1.01 for mild).
- **Why drones might not reduce the total:** they may *detect* more minor incidents (reporting effect) while preventing the serious ones. Worth saying out loud.
- **Severe caveat:** only 194 severe events in the training years, so intervals are wide and exact sizes are unstable. Quote the direction, not the decimals.

## 6. Caveats I should state
1. **Association, not causation.** Lifeguards, drones and flags were probably placed where risk is already high, which hides some of their benefit.
2. **Season and patrols are entangled.** Patrols run ~80% of beach-months Sep–Apr but 12% May–Aug, so the month effects and lifeguard effect share credit.
3. **Campaigns are set per postcode and only in summer**, so the campaign effect overlaps with season and first-aid. Don't over-read its exact size.
4. **Forecasting needs future inputs** (visitors, weather, safety hours) that we don't have. These must be assumed: same-month recent averages for visitors and weather; safety held at the latest year (the "no extra funding" baseline).
5. **Don't use `response_min` as a predictor:** it's only known after an incident.

## 7. Still to do (my part)
1. **Validate (step 05):** compare simple vs richer models on the held-out year. Primary score: out-of-sample negative log-likelihood; also predicted vs actual total and error per beach. Benchmark: "same as last year". Then rolling-origin (several test years) to check stability.
2. **Forecast (step 06):** refit on all 10 years, build next year's inputs (80 beaches × 12 months), predict by severity, and show a range (simulate from the NB).
3. **Fix before presenting:** remove the "earlier AI notes" wording in step 04; make the FY2020–21 description consistent.
4. **Target:** validation and forecast done by **Tue 20 Oct** (analysis freeze).

## 8. What I need from the others
- **Aiden:** do his severity results agree with the severe-model effects above (drones, lifeguards, swell)? Where they differ, whose is more trustworthy?
- **Sunny:** confirm the safety levers to use for Task 2 (lifeguard hours, drone hours, campaign, first-aid, PA, flags), and the format of the expected-incidents table I hand over (beach × month × severity).
- **Both:** agree the shared test year (Sep 2025 – Aug 2026) and what "same as last year" benchmark we all compare against.
