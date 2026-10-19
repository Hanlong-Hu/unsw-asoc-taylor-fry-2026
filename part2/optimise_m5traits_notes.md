# Part 2 optimiser: switching to the chosen severe model (M5_traits)

Companion to `part2/optimise_m5traits.Rmd`. The original `part2/optimise.Rmd` is unchanged.

**In one paragraph.** The original optimiser fitted its own simple model of severe incidents, separate
from the one chosen in Part 1. That model left out visitor numbers, season, weather and beach hazard, so it
mixed up "busy, dangerous beaches get more lifeguards" with "lifeguards cause incidents". It ended up
spending 92% of the budget on first-aid training. The new version plans against the Part 1 model
(`M5_traits`). Under that model first aid has no measurable effect, and the money goes to drones,
lifeguards, summer campaigns and rip flags, mostly in winter and at under-patrolled, high-hazard beaches.
Expected severe incidents next year fall from about 21 to about 9 in the model. That number is an upper
estimate of the benefit, for reasons given in section 5.

Contents

1. Headline comparison
2. How the pieces fit: both parts step by step, in plain terms
3. Misconceptions and bugs in the original optimiser
4. Differences in approach, side by side
5. New issues the switch brings in, and how they are handled
6. Sensitivity checks
7. Open questions for the team

---

## 1. Headline comparison

| | Original `optimise.Rmd` | New `optimise_m5traits.Rmd` |
|---|---|---|
| Model of severe incidents | Own Poisson GLM, 6 safety levers only | Part 1 choice: negative binomial `M5_traits`, refitted on all 10 years |
| Planning year | FY2026 (Sep 2025 to Aug 2026), already happened | FY2027 (Sep 2026 to Aug 2027), the forecast year |
| Baseline severe incidents | 19.3 (fitted values for FY2026) | 21.4 (Part 1 forecast, step 06) |
| After $2M | 6.7 (-65%) | 8.9 (-59%) |
| Lifeguards | $0 (model says they *increase* risk) | $403k (about 6,900 casual hours, no FTEs) |
| Drones (hours + hardware) | $85k | $1,177k ($903k hours + $274k for 29 drones) |
| Campaigns | $75k | $330k (22 postcodes) |
| First aid | **$1,840k** | $0 (no effect in the chosen model) |
| Flags/signage | $0 | $90k (18 beaches) |
| PA systems | $0 | $0 (no effect in either model) |
| Close calls (knock-on) | not reported | 316 to 170 (-46%) |
| Range for incidents avoided (effect-size uncertainty only) | not reported | 10.9 to 13.7 |

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
33). Hand-off file `forecast_fy2027.rds` contains `forecast` (960 beach-month rows with `mu_sev`, `mu_cc`)
and `final` (the refitted models).

### Part 2: spend the $2M (`part2/optimise_m5traits.Rmd`)

**1. Model and baseline**
> *In plain terms:* start from Part 1's forecast of about 21 severe incidents next year, and read off how
> much each safety measure lowers the risk.

Technical: loads `forecast_fy2027.rds`. Baseline `mu0 = mu_sev` per beach-month. Lever coefficients come
from `final$sev`. Any lever with a coefficient >= 0 (first aid, PA) is switched off.

**2. Prices and settings**
> *In plain terms:* what each item costs, plus practical limits: no more lifeguard hours than the busiest
> beach has ever had, 120 drone hours a month per drone, and a real roster (at least 50 hours) when
> patrolling a beach-month that currently has none.

Technical: costs from `part1/pricing.csv`. `MIN_LG = 50` and `MIN_DR = 5` hours are the new minimum blocks
(section 5.1).

**3. Precompute**
> *In plain terms:* for every beach-month, work out the most each measure could add and how much risk that
> would remove. Months where little can change are left out to keep the problem small.

Technical: room for each lever per row; tangent grids for `exp()` and for each `log1p` gain; rows kept if
they hold 95% of the achievable reduction (543 of 960).

**4. The MILP**
> *In plain terms:* a solver searches all affordable mixes of purchases for the one with the fewest
> expected severe incidents. Curves are approximated by straight-line pieces so the solver can handle them.

Technical: minimises the sum of `mu0 * exp(delta)`. `exp` is outer-approximated by K = 8 tangents; each
`log1p` hours gain is capped by J = 8 tangents. Binary switches enforce the minimum blocks. HiGHS, 300 s.

**5. Results**
> *In plain terms:* put the chosen purchases back into the real model, count incidents avoided and the
> cost, show which purchases do the work, and give a range.

Technical: exact recompute over all 960 rows; close-call knock-on from `final$cc`; one-lever-at-a-time
attribution; 2,000 draws of the lever coefficients from their covariance matrix.

---

## 3. Misconceptions and bugs in the original optimiser

Ordered by how much they change the answer.

### 3.1 It used a different, much weaker model than Part 1 chose (largest effect)

**What it did.** `glm(n_sev ~ lg_hrs + drone_hrs + campaign_idx + first_aid_cap + pa_system + flags,
family = poisson)`. That is only the six levers: no visitors, no season, no weather, no beach hazard.

**Why it is wrong.** Safety resources are not placed at random. Busy, dangerous beaches get the most
lifeguards, and patrols run in summer when visits peak. With nothing in the model to absorb those
differences, each lever's coefficient picks up whatever it happens to move with:

| Lever | Original Poisson | Chosen `M5_traits` (RR, 95% CI) |
|---|---|---|
| Lifeguard hours | **+0.0005 per hour (harmful, p < 0.001)** | 0.86 per log-unit (0.80 to 0.92), protective |
| Drone hours | -0.009 per hour | 0.77 per log-unit (0.70 to 0.85) |
| Campaign | -1.09 | RR 0.24 at full index (0.11 to 0.54) |
| First aid capacity | **-0.043 per point (strong)** | RR 1.003 per point (0.988 to 1.017): no effect |
| PA system | +0.05 (not significant) | 1.03 (0.74 to 1.45): no effect |
| Flags | -0.06 (not significant) | 0.64 (0.43 to 0.94): protective |

**Consequence.** The original optimiser could never buy lifeguards (its own warning said so). It treated
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

**Fix.** The new MILP linearises `log1p` with tangent lines (section 4 of the Rmd) and recomputes exactly
afterwards. This needed the minimum blocks in 5.1.

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
original model looks far more certain than it is (e.g. first aid at z = -8.8). That matters as soon as
you quote a range.

**Fix.** Negative binomial via `M5_traits`, and a coefficient-uncertainty range in section 5 of the Rmd.

### 3.6 File paths: the original does not run as written

- `read.csv("../pricing.csv")`: the pricing file is at `part1/pricing.csv`; there is no `pricing.csv` at the
  project root. Knitting stops at section 2.
- `readRDS("../part1/panel.rds")` works only if the working directory is `part2/`. The Part 1 files use
  `rprojroot` so they run from anywhere; the new file does the same.

### 3.7 Solver settings and status

- `control = list(mip_rel_gap = GAP)` is not an option the HiGHS ROI plugin accepts. It prints a warning and
  is ignored, so the 1% gap never applied. The plugin only exposes `time_limit`.
- `ompr` reports `status = "error"` whenever HiGHS stops at the time limit, even with a good plan in hand.
  On this problem HiGHS stops at 300 s with a gap of about 0.06%, so the plan is effectively optimal. The new
  file prints the HiGHS message and gap, and stops only if no feasible plan exists.

### 3.8 "MILP objective is a lower bound" is not quite true

The tangent approximations are optimistic, but rows dropped by the `ACTIVE_SHARE` speed-up are held at
baseline in the MILP. Beach-wide purchases (FTEs, flags, campaigns) still help those rows in the exact
recompute. So the exact result can come in *below* the MILP objective (here: 8.9 exact vs 8.97 from the
MILP). The wording is corrected in the new file.

### 3.9 Packages not installed

`ompr`, `ompr.roi`, `ROI`, `ROI.plugin.glpk` and `ROI.plugin.highs` are not in the shared R library on this
machine, so neither optimiser runs until they are installed:

```r
install.packages(c("ompr", "ompr.roi", "ROI", "ROI.plugin.highs", "ROI.plugin.glpk"))
```

---

## 4. Differences in approach, side by side

| Aspect | Original | New | Why |
|---|---|---|---|
| Source of effects | Refits its own GLM on `panel.rds` | Reads `final$sev` from step 06 | One model across forecast, factors and allocation |
| Family | Poisson | Negative binomial | Overdispersion (step 04) |
| Exposure | None | `offset(log(visitors))` | Effects per visitor, not per crowd |
| Controls | None | Season, period, weather, beach traits, visitor mix | Removes confounding |
| Lifeguard and drone terms | Linear hours | `log1p(hours)` | Matches Part 1; diminishing returns |
| Planning year | FY2026 (history) | FY2027 (forecast) | The decision is about next year |
| Baseline | 19.3 (fitted values) | 21.4 (step 06) | Same "do nothing" number as Part 1 slides |
| Weather | FY2026 actual | 10-year replay average | Keeps stormy months in (step 06, section 2) |
| Linearisation | K = 4 tangents on `exp` | K = 8 on `exp` + J = 8 on each `log1p` | Wider range of `delta`; concave hours |
| New-patrol rule | none (hours were linear) | Min 50 lifeguard h / 5 drone h where currently zero | Stays inside the observed range (5.1) |
| Levers with coefficient >= 0 | Left in, warned | Switched off explicitly | Same result, clearer |
| Paths | `../` relative to `part2/` | `rprojroot`, like Part 1 | Runs from anywhere |
| Outputs | Spend, before/after, by beach/postcode | Plus close-call knock-on, per-lever attribution, cost per incident avoided, coefficient-uncertainty range, by-month table | What the panel will ask |

Unchanged on purpose: budget ($2M), cost items and prices, `AMORT = 1` (one-offs charged in full this
year), max 2 FTE per beach, max 4 first-aid purchases per postcode, drone 120 h/month capacity, campaign sets
the index to at least 0.7 in Nov to Feb, first aid starts the month after purchase, lifeguard cap = the
highest observed beach-month, and minimising **severe** incidents (the brief's objective).

---

## 5. New issues the switch brings in, and how they are handled

### 5.1 The `log1p` curve is very steep at zero hours

> *In plain terms:* the model says the first hour of patrol at an unpatrolled beach is worth a lot. Taken
> literally, the best plan would be one hour at hundreds of beach-months, which is not a real roster.

`log1p(0) = 0` and `log1p(1) = 0.69`, so one hour at a beach-month with no patrol is predicted to cut its
severe risk by about 10% (RR 0.859^0.69). The data never shows anything like that: no beach-month in ten
years had between 1 and 48 lifeguard hours (smallest positive 49, 5th percentile 97). For drones, the
smallest positive value is 4 hours.

**Handled by:** minimum blocks. If extra casual hours go into a beach-month that currently has none, there
must be at least `MIN_LG = 50` hours (a FTE's 146 h/month always clears this). Drones need at least
`MIN_DR = 5` hours. Most winter casual blocks sit exactly at 50 hours (e.g. 200 h = 4 months x 50 at many
beaches), so the model is spending wherever "unpatrolled to patrolled" is cheapest. That raised the worry
that the setting drives the answer. Section 6 checks it: at 100 hours the plan barely changes (58% instead
of 59% fewer severe incidents).

Worth raising with the Part 1 owner: a `patrolled` dummy alongside `log_lg` would separate "any patrol"
from "more hours", and would make this choice come from the data rather than from a setting.

### 5.2 The drone effect is large, and drones take most of the money

At RR 0.77 per log-unit, going from 0 to 120 drone hours a month (`log1p(120) = 4.8`) predicts about 71%
fewer severe incidents in that beach-month. That is inside the observed range (up to 150 h), but it rests
on 35 beaches that already fly drones, which were not chosen at random. The plan buys 29 new drones
and about 20,000 flight hours. Treat drones as the strongest lever *in the model* and check how sure we
are of that before the slides commit to it. A good test is to show that the ranking of levers holds when
the drone coefficient is at the edge of its interval.

### 5.3 Association, not cause (applies to every number in the plan)

The same caveat as step 04 and step 06: the effects come from where and when resources happened to be in
the past. If resources went where risk was highest, the benefits are *understated*. But the plan also puts
patrols where there have never been many (winter, quieter beaches), so it relies on the effect carrying
over to new places and seasons. The coefficient range in the Rmd (10.9 to 13.7 incidents avoided) covers only
estimation noise, not this. In the slides, present the reduction as the model's estimate with that caveat,
not as a promise. Step 06 also shows that a single year's severe count varies a lot by chance (90% range 15
to 33 with no change at all).

### 5.4 Only severe incidents are optimised

The brief asks to minimise severe incidents, so that is the objective. Close calls also fall a lot as a
knock-on (316 to 170 (-46%)) because the same levers protect against them. That is a useful supporting point. Mild
incidents are not tracked.

### 5.5 Delivery is the implementation question

The plan asks for a lot of winter rostering: casual lifeguards at many beaches in May to August, and
29 new drones with operators. Questions to have answers ready for in Q&A:

- Can SLSC staff winter patrols at that many beaches?
- One trained operator per drone is assumed (one $450 training fee per drone). Is that enough cover?
- Should there be a cap per beach or region for fairness? The optimiser has no fairness constraint and
  spreads money only where the model says it helps most.

### 5.6 What "no effect" means for first aid and PA systems

Both have coefficients of about zero with tight intervals (first aid 0.988 to 1.017 per point). This is a
**finding**, not an omission: the data gives no evidence that they reduce severe incidents. Plausible
reasons are that first aid acts after an incident (it could lower deaths, but our severity label may not
pick that up) and that PA systems are mostly at already-patrolled beaches. Say this explicitly in the "why
not alternatives" part of Task 2.

---

## 6. Sensitivity checks

Each row is a full re-run of the new optimiser with one setting changed.

| Run | Severe after | Reduction | Lifeguards | Drones | Campaigns | Flags |
|---|---|---|---|---|---|---|
| Base (`MIN_LG = 50`, `AMORT = 1`) | 8.9 | -59% | $403k (about 6,900 casual hours, no FTEs) | $1,177k ($903k hours + $274k for 29 drones) | $330k (22 postcodes) | $90k (18 beaches) |
| `MIN_LG = 100` | 9.0 | -58% | $382k | $1,213k (30 drones) | $315k | $90k |
| `AMORT = 3` (one-offs spread over a 3-year life) | 8.6 | -60% | $465k | $1,152k (35 drones) | $345k | $38k (23 beaches) |

**The plan is stable.** All three runs avoid 58% to 60% of expected severe incidents, rank the levers the same way (drones, then lifeguards, then campaigns, then flags) and never fund first aid or PA systems. Doubling the minimum patrol block moves only about $20k out of lifeguards, so the concern in 5.1 does not drive the answer. Spreading one-off costs over three years makes hardware (drones, flags) cheaper this year, so more of the budget goes to hours and more beaches get drones. In every run HiGHS ends within 0.06% of the best possible plan.

---

## 7. Open questions for the team

1. **Adopt this as the Task 2 model?** It keeps the forecast, the factor analysis and the allocation on one
   model, which is the strongest story for Q&A. If yes, retire `optimise.Rmd` or mark it superseded.
2. **Minimum patrol block.** Is 50 hours a sensible smallest casual roster for a winter month, given the data
   minimum of 49? Or should the Part 1 model get a `patrolled` dummy (5.1)?
3. **Amortisation.** The pricing file gives drones a 3-year life. Charging one-offs in full (AMORT = 1) is
   conservative for a one-year budget. Decide which to present and say so.
4. **Fairness or coverage constraints.** For example, a minimum spend per region, or a cap per beach.
   Simple to add as MILP constraints if wanted.
5. **"Why not alternatives" slide.** The one-lever attribution table in the Rmd gives cost per severe
   incident avoided for each lever. That is the natural evidence for why first aid and PA systems were not
   funded.
