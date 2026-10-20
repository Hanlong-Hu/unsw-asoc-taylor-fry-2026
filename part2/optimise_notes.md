# Part 2 optimiser notes

Companion to `part2/optimise.Rmd`, the single Task 2 optimiser. On 2026-10-20 it absorbed
`optimise_m5traits.Rmd` (PR #1), a parallel version built on the same Part 1 model; section 5 says what came
from each. Robustness checks are in `presentation_notes.md` §08 and `part2/robustness/`.

**In one paragraph.** The first optimiser fitted its own simple model of severe incidents, separate from the
one chosen in Part 1. That model left out visitor numbers, season, weather and beach hazard, so it mixed up
"busy, dangerous beaches get more lifeguards" with "lifeguards cause incidents". It ended up spending 92% of
the budget on first-aid training. The current version plans against the Part 1 model (`M5_traits`). Under that
model first aid has no measurable effect, and the money goes to drones, winter lifeguard patrols, summer
campaigns and rip flags. Expected severe incidents next year fall from about 21.4 to about 9.0: about 12.5
avoided (90% range 11 to 16). That is the model's estimate of the benefit; section 6 explains why it is likely
to be an upper estimate.

Contents

1. Headline comparison
2. How the pieces fit: both parts step by step, in plain terms
3. Misconceptions and bugs in the first optimiser
4. Differences in approach, side by side
5. How the two M5_traits optimisers were merged
6. Issues the switch brings in, and how they are handled
7. Sensitivity checks
8. Open questions for the team

---

## 1. Headline comparison

| | First `optimise.Rmd` (Poisson GLM) | Current `optimise.Rmd` |
|---|---|---|
| Model of severe incidents | Own Poisson GLM, 6 safety levers only | Part 1 choice: negative binomial `M5_traits`, refitted on all 10 years |
| Planning year | FY2026 (Sep 2025 to Aug 2026), already happened | FY2027 (Sep 2026 to Aug 2027), the forecast year |
| Baseline severe incidents | 19.3 (fitted values for FY2026) | 21.4 (Part 1 forecast, step 06) |
| After $2M | 6.7 (-65%) | 9.0 (-58%) |
| Lifeguards | $0 (model says they *increase* risk) | $392k (6,752 casual hours, no FTEs) |
| Drones (hours + hardware) | $85k | $1,163k ($908k hours + $255k for 27 drones) |
| Campaigns | $75k | $330k (22 postcodes) |
| First aid | **$1,840k** | $0 (no effect in the chosen model) |
| Flags/signage | $0 | $115k (23 beaches) |
| PA systems | $0 | $0 (no effect in either model) |
| Close calls (knock-on) | not reported | 316 to 169 (-47%) |
| Range for severe incidents avoided | not reported | 11 to 16 (5,000 simulated years: weather, effect sizes) |
| Cost per severe incident avoided | not reported | about $160k |

The two plans have almost nothing in common. The main reason is the model (section 3, items 1 and 2), not
the optimiser.

---

## 2. How the pieces fit: both parts step by step

Each step has a plain-terms summary first, then the technical detail.

### Part 1: forecast next year's incidents (`part1/`)

**01 Data prep** (`01_data_prep.Rmd`)
> *In plain terms:* turn the list of individual incidents into one row per beach per month, with how many
> mild, close-call and severe incidents happened there.

Technical: joins `incidents.csv` to `beach_monthly.csv`, giving 80 beaches x 120 months = 9,600 rows, with
counts `n_mild`, `n_cc`, `n_sev` by worst outcome. Output `panel.rds`.

**02 EDA** (`02_eda.Rmd`)
> *In plain terms:* look at the counts before modelling. Which beaches and months are worst, and do
> incidents simply follow the crowds?

Technical: incidents rise with visitors, but not one-for-one. Severe risk per visit is higher in winter.
Counts are overdispersed (variance above the mean) for mild and close calls.

**03 Features** (`03_features.Rmd`)
> *In plain terms:* pick which beach, weather and safety measurements go into the model, and drop
> duplicates that measure the same thing.

Technical: adds `log_lg = log1p(lg_hrs)`, `log_drone = log1p(drone_hrs)`, `rips_per_km`, month factor,
`period_2021` (the FY2020-21 dip), financial year. Drops near-duplicates (e.g. `swell_avg` vs `swell_max`,
`n_bins`, `icecream_visits`). Output `panel_f.rds`.

**04 Baseline models** (`04_baseline_models.Rmd`)
> *In plain terms:* fit a model for each severity that says how much each factor raises or lowers the
> number of incidents *per visitor*, holding everything else fixed.

Technical: Poisson, then negative binomial GLMs with `offset(log(visitors))`. Rate ratios (`exp(coef)`) are
read as "x up by 1 multiplies incidents per visitor by RR". Overdispersion confirms negative binomial.

**05 Validation** (`05_validation.Rmd`)
> *In plain terms:* test candidate models on years they had not seen, and keep the one that predicts best.
> Severe incidents are too rare to learn each beach separately, so that model learns from beach features
> (rips, rocks, patrols) shared across beaches.

Technical: rolling-origin log score over 5 folds, plus calibration and top-10 capture, with an XGBoost
challenger. Choice: mild = `M6_beachFE` (beach fixed effects); close calls and severe = `M5_traits`.
Saved to `chosen_specs.rds`.

**06 Forecast** (`06_forecast.Rmd`)
> *In plain terms:* refit the chosen models on all ten years and predict next year if nothing changes,
> with a range. This "no extra funding" forecast is what Part 2 tries to improve on.

Technical: FY2027 inputs: visitors from a 3-year mean plus growth, safety held at FY2026 levels, and weather
replayed from each of the last 10 years and averaged. Severe forecast is about 21.4 (90% range about 15 to
33). Hand-off file `forecast_fy2027.rds` contains `forecast` (960 beach-month rows with `mu_sev`, `mu_cc`),
`newdata` (the inputs) and `final` (the refitted models).

### Part 2: spend the $2M (`part2/optimise.Rmd`)

**1. Model and baseline**
> *In plain terms:* start from Part 1's forecast of about 21 severe incidents next year, and read off how
> much each safety measure lowers the risk.

Technical: loads `forecast_fy2027.rds`. Baseline `mu0 = mu_sev` per beach-month; lever coefficients from
`final$sev`, shown with rate ratios and 95% intervals. Levers with a coefficient >= 0 (first aid, PA) are
not bought.

**2. Prices and settings**
> *In plain terms:* what each item costs, plus practical limits: no more lifeguard hours than the busiest
> beach-month has ever had, 120 drone hours a month per drone.

Technical: costs from `part1/pricing.csv`; `AMORT = 1` (one-off costs charged in full this year).

**3. Precompute**
> *In plain terms:* for every beach-month, work out the most each measure could add, and require a real
> roster when patrolling a beach-month that currently has none.

Technical: room for each lever per row; minimum new patrol `MIN_LG` = 97 hours (5th percentile of patrolled
months, computed from the data); chord lines for the hours each `log1p` gain needs; tangent lines for `exp()`.

**4. The MILP**
> *In plain terms:* a solver searches all affordable mixes of purchases for the one with the fewest
> expected severe incidents. Curves are approximated by straight-line pieces so the solver can handle them.

Technical: decision variables are the `log1p` gains; hours paid for must lie above chord lines (never
under-costed); `exp` is approximated by K = 10 tangents. Solved with the `highs` package directly at a 1%
gap: Optimal at about 0.6% in under a minute.

**5. Results**
> *In plain terms:* put the chosen purchases back into the real model, count incidents avoided and the
> cost, show which purchases do the work, and where the money goes.

Technical: exact recompute from the hours bought; close-call knock-on from `final$cc`; one-lever-at-a-time
attribution with cost per incident; allocation by beach (with months patrolled), postcode and month.

**6. Uncertainty** — 5,000 simulated years drawing weather, effect sizes and chance, with the plan fixed.

**7. Alternatives** — spread evenly, summer-only patrols and education only, scored on the same model.

---

## 3. Misconceptions and bugs in the first optimiser

Ordered by how much they change the answer.

### 3.1 It used a different, much weaker model than Part 1 chose (largest effect)

**What it did.** `glm(n_sev ~ lg_hrs + drone_hrs + campaign_idx + first_aid_cap + pa_system + flags,
family = poisson)`. That is only the six levers: no visitors, no season, no weather, no beach hazard.

**Why it is wrong.** Safety resources are not placed at random. Busy, dangerous beaches get the most
lifeguards, and patrols run in summer when visits peak. With nothing in the model to absorb those
differences, each lever's coefficient picks up whatever it happens to move with:

| Lever | First Poisson | Chosen `M5_traits` (RR, 95% CI) |
|---|---|---|
| Lifeguard hours | **+0.0005 per hour (harmful, p < 0.001)** | 0.86 per log-unit (0.80 to 0.92), protective |
| Drone hours | -0.009 per hour | 0.77 per log-unit (0.70 to 0.85) |
| Campaign | -1.09 | RR 0.24 at full index (0.11 to 0.54) |
| First aid capacity | **-0.043 per point (strong)** | RR 1.003 per point (0.988 to 1.017): no effect |
| PA system | +0.05 (not significant) | 1.03 (0.74 to 1.45): no effect |
| Flags | -0.06 (not significant) | 0.64 (0.43 to 0.94): protective |

**Consequence.** The first optimiser could never buy lifeguards (its own warning said so). It treated
first aid as the best buy: +10 points multiplies risk by about 0.65 across a whole postcode for $20k. That
is why it put $1.84M of $2M into first aid and claimed a 65% reduction. In the chosen model, first aid's
apparent effect disappears once beach hazard and season are accounted for.

**Fix.** Plan against `final$sev` from step 06, the model that won the out-of-sample comparison in step 05.

### 3.2 No exposure offset

**What it did.** Modelled the raw count of severe incidents, not incidents per visitor.

**Why it matters.** Visitors are the biggest driver of counts. Without `offset(log(visitors))`, any lever
that grows with crowds (lifeguards especially) looks harmful. This is the main mechanism behind the
positive lifeguard coefficient in 3.1.

**Fix.** `M5_traits` has the offset. The optimiser changes only safety inputs, so visitors stay fixed at
the forecast and drop out of the "change" (`delta`) term.

### 3.3 Linear hours instead of `log1p(hours)`

**What it did.** Each extra lifeguard or drone hour had the same effect wherever it went.

**Why it matters.** Part 1 models hours on a log scale (`log1p`): doubling hours has a fixed effect, so an
hour at a beach with 50 hours is worth far more than one at Bondi with 2,500. That is what moves money
towards winter and under-patrolled beaches, which is also where step 06 puts the severe risk (May to
August holds about 44% of expected severe incidents).

**Fix.** The MILP works in `log1p` gains with chord lines on the hours they cost (section 3 of the Rmd) and
recomputes exactly afterwards. This needed the minimum patrol block in 6.1.

### 3.4 It planned last year, not next year

**What it did.** Took the last 12 months of the panel (FY2026) as the "planning window", using fitted
values from a model trained on those same months with that year's actual weather and visitors. Baseline:
19.3.

**Why it matters.** The decision is about FY2027. Part 1 already produced the FY2027 baseline (21.4), with
assumed visitor growth and weather replayed over ten years so that stormy months are not averaged away.
Two different baselines would put two different "do nothing" numbers on the slides.

**Fix.** Use `forecast_fy2027.rds`. Because the safety terms add to the linear predictor and do not
interact with weather, multiplying the replay-averaged forecast by `exp(delta)` is exact.

### 3.5 Poisson rather than negative binomial

**What it did.** Poisson family.

**Why it matters (moderately).** Step 04 found overdispersion, and the chosen severe model has theta of
about 1.5. Poisson point estimates can still be reasonable, but its standard errors are too small, so the
first model looks far more certain than it is (e.g. first aid at z = -8.8). That matters as soon as you
quote a range.

**Fix.** Negative binomial via `M5_traits`, and a simulated range in section 6 of the Rmd.

### 3.6 File paths: the first version did not run as written

- `read.csv("../pricing.csv")`: the pricing file is at `part1/pricing.csv`. Knitting stopped at section 2.
- `readRDS("../part1/panel.rds")` worked only if the working directory was `part2/`.

**Fix.** `rprojroot`, like Part 1, so the file runs from anywhere.

### 3.7 Solver settings and status

- `control = list(mip_rel_gap = GAP)` is not an option the HiGHS ROI plugin accepts. It printed a warning and
  was ignored, so the 1% gap never applied; the plugin only passes `time_limit`. Without a gap, HiGHS ran
  to its 300-second limit and `ompr` reported `status = "error"` even with a good plan in hand.

**Fix.** The model goes to the `highs` package directly (a small solver function for `ompr`) with
`mip_rel_gap = 0.01`. It now finishes Optimal at about a 0.6% gap in under a minute.

### 3.8 "MILP objective is a lower bound" is not quite true

The tangent lines on `exp()` are optimistic, but the chord lines on hours are conservative, and any rows
left out of the MILP are held at baseline even though beach-wide purchases help them. So the MILP objective
is only a guide; section 5 of the Rmd recomputes the result exactly over all 960 beach-months.

### 3.9 Packages not installed

`ompr`, `ompr.roi`, `ROI` and `highs` were not in the shared R library, so the optimiser did not run until
they were installed:

```r
install.packages(c("ompr", "ompr.roi", "ROI", "highs"))
```

---

## 4. Differences in approach, side by side

| Aspect | First version | Current | Why |
|---|---|---|---|
| Source of effects | Refits its own GLM on `panel.rds` | Reads `final$sev` from step 06 | One model across forecast, factors and allocation |
| Family | Poisson | Negative binomial | Overdispersion (step 04) |
| Exposure | None | `offset(log(visitors))` | Effects per visitor, not per crowd |
| Controls | None | Season, period, weather, beach traits, visitor mix | Removes confounding |
| Lifeguard and drone terms | Linear hours | `log1p(hours)` | Matches Part 1; diminishing returns |
| Planning year | FY2026 (history) | FY2027 (forecast) | The decision is about next year |
| Baseline | 19.3 (fitted values) | 21.4 (step 06) | Same "do nothing" number as Part 1 slides |
| Weather | FY2026 actual | 10-year replay average | Keeps stormy months in (step 06, section 2) |
| Linearisation | K = 4 tangents on `exp` | `log1p` gains as variables, chord lines on hours, K = 10 tangents on `exp` | Exact effect in the gains; cost never understated |
| New-patrol rule | none (hours were linear) | Min 97 lifeguard hours where a beach-month has none | Stays inside the observed range (6.1) |
| Levers with coefficient >= 0 | Left in, warned | Not bought | Same result, clearer |
| Solver | HiGHS via ROI, gap ignored | `highs` directly, 1% gap | Optimal in under a minute |
| Paths | `../` relative to `part2/` | `rprojroot`, like Part 1 | Runs from anywhere |
| Outputs | Spend, before/after, by beach/postcode | Plus close-call knock-on, per-lever attribution, cost per incident avoided, simulated range, alternatives, by-month table | What the panel will ask |

Unchanged on purpose: budget ($2M), cost items and prices, `AMORT = 1` (one-offs charged in full this
year), max 2 FTE per beach, drone 120 h/month capacity, campaign sets the index to at least 0.7 in Nov to
Feb, lifeguard cap = the highest observed beach-month, and minimising **severe** incidents (the brief's
objective).

---

## 5. How the two M5_traits optimisers were merged

Two versions were written in parallel on the same model and reached the same answer:

| | `optimise.Rmd` (kept) | `optimise_m5traits.Rmd` (merged in, then removed) |
|---|---|---|
| `log1p` handling | Gains are the variables; chord lines on the hours they cost | Hours are the variables; tangent lines cap the gain |
| Minimum new patrol | 97 h (5th percentile of patrolled months) | 50 h lifeguards, 5 h drones (just above the smallest observed) |
| Solver | `highs` directly, 1% gap, about 1 minute | HiGHS via ROI, 300 s limit (gap about 0.06%) |
| Uncertainty | 5,000 years: weather, effect sizes, chance | Effect sizes only (2,000 draws) |
| Result | 21.4 → 9.0; drones $1,163k (27 new) | 21.4 → 8.9; drones $1,177k (29 new) |

**Kept from `optimise.Rmd`:** the formulation, minimum block, solver call, simulation, alternatives and the
`plan_delta()` function the robustness scripts reuse. These are what the deck's numbers come from, so the
deck did not change.

**Brought in from `optimise_m5traits.Rmd`:** plain-language callouts in each section, the lever table with
rate ratios and intervals, the close-call knock-on, the one-lever attribution table with cost per incident,
the months patrolled per beach, before/after by month, and these notes.

---

## 6. Issues the switch brings in, and how they are handled

### 6.1 The `log1p` curve is very steep at zero hours

> *In plain terms:* the model says the first hour of patrol at an unpatrolled beach is worth a lot. Taken
> literally, the best plan would be one hour at hundreds of beach-months, which is not a real roster.

`log1p(0) = 0` and `log1p(1) = 0.69`, so one hour at a beach-month with no patrol is predicted to cut its
severe risk by about 10% (RR 0.859^0.69). The data never shows anything like that: no beach-month in ten
years had between 1 and 48 lifeguard hours (smallest positive 49, 5th percentile 97). Without a minimum, the
solver spread patrols of a median 8 hours over 353 unpatrolled beach-months.

**Handled by:** a minimum block. If extra hours go into a beach-month that currently has none, there must be
at least `MIN_LG` = 97 hours, the size of the smallest patrols actually run. The choice barely matters:
the earlier version with 50 hours gave 8.9 severe incidents after the plan, and 100 hours gave 9.0 (section
7). Drones get no block: they already fly small months in the data (smallest positive 4 hours, 5th
percentile 7).

Worth raising with the Part 1 owner: a `patrolled` dummy alongside `log_lg` would separate "any patrol" from
"more hours", and would make this choice come from the data rather than from a setting.

### 6.2 The drone effect is large, and drones take most of the money

At RR 0.77 per log-unit, going from 0 to 120 drone hours a month (`log1p(120) = 4.8`) predicts about 71%
fewer severe incidents in that beach-month. That is inside the observed range (up to 150 h), but it rests on
the 35 beaches that already fly drones, which were not chosen at random. The plan buys 27 new drones and
about 20,000 flight hours. The robustness checks (`presentation_notes.md` §08) test this: the drone effect is
stable across years, holds within the same beach, improves forecasts and matches outcomes where drones
started; with the drone effect halved the plan still avoids about 10.

### 6.3 Association, not cause (applies to every number in the plan)

The effects come from where and when resources happened to be in the past. If resources went where risk
was highest, the benefits are *understated*. But the plan also puts patrols where there have never been many
(winter, quieter beaches), so it relies on the effect carrying over to new places and seasons. Present the
reduction as the model's estimate with that caveat, not as a promise. A single year's severe count also
varies a lot by chance (90% range 15 to 33 with no change at all; 4 to 16 with the plan).

### 6.4 Only severe incidents are optimised

The brief asks to minimise severe incidents, so that is the objective. Close calls also fall a lot as a
knock-on (316 to 169, -47%) because the same levers protect against them. Mild incidents are not tracked.

### 6.5 Delivery is the implementation question

The plan asks for a lot of winter rostering and 27 new drones with operators. Questions to have answers
ready for in Q&A:

- Can SLSC staff winter patrols at 22 beaches?
- One trained operator per drone is assumed (one $450 training fee per drone). Is that enough cover?
- Should there be a cap per beach or region for fairness? The optimiser has no fairness constraint and
  spreads money only where the model says it helps most.

### 6.6 What "no effect" means for first aid and PA systems

Both have coefficients of about zero with tight intervals (first aid 0.988 to 1.017 per point). This is a
**finding**, not an omission: the data gives no evidence that they reduce severe incidents. Plausible
reasons are that first aid acts after an incident (it could lower deaths, but our severity label may not
pick that up) and that PA systems are mostly at already-patrolled beaches.

---

## 7. Sensitivity checks

**Settings** (run on the earlier `optimise_m5traits.Rmd` formulation, which gives the same plan within 0.1
severe incidents):

| Run | Severe after | Reduction | Lifeguards | Drones | Campaigns | Flags |
|---|---|---|---|---|---|---|
| `MIN_LG = 50`, `AMORT = 1` | 8.9 | -59% | $403k | $1,177k (29 drones) | $330k | $90k (18 beaches) |
| `MIN_LG = 100` | 9.0 | -58% | $382k | $1,213k (30 drones) | $315k | $90k |
| `AMORT = 3` (one-offs over a 3-year life) | 8.6 | -60% | $465k | $1,152k (35 drones) | $345k | $38k (23 beaches) |

The plan is stable: every run avoids 58% to 60%, ranks the levers the same way and never funds first aid or
PA systems. Spreading one-off costs over three years makes hardware cheaper this year, so more beaches get
drones.

**Budget and effect sizes** (current `optimise.Rmd`, via `part2/robustness/scenario.R`):

| Budget | $0.5M | $1M | $1.5M | $2M | $2.5M | $3M |
|---|---|---|---|---|---|---|
| Severe avoided | 8.5 | 10.6 | 11.8 | 12.5 | 13.0 | 13.2 |

Re-optimised with the drone effect halved: 10.2 avoided. With within-beach coefficients: 11.6. With
lifeguards and flags set to no effect: 11.0. All pessimistic at once: 8.3. In every case the current plan
keeps 94–99% of the best result for that case (details in `presentation_notes.md` §08).

---

## 8. Open questions for the team

1. **Minimum patrol block.** 97 hours is the data's 5th percentile; 50 or 100 change little (section 7).
   Or should the Part 1 model get a `patrolled` dummy (6.1)?
2. **Amortisation.** The pricing file gives drones a 3-year life. Charging one-offs in full (`AMORT = 1`) is
   conservative for a one-year budget. Decide which to present and say so.
3. **Fairness or coverage constraints.** For example, a minimum spend per region, or a cap per beach.
   Simple to add as MILP constraints if wanted.
