# Presentation notes: Task 1 (predicting incidents)

What we did at each step, why, the numbers to quote, and likely panel questions. Source notebooks are in `part1/`.

## 01 Data prep: building the beach-month table

**In one sentence:** we turned the raw files into one table with a row for every beach in every month, giving the number of incidents by severity next to that beach's conditions that month.

**What we did**
1. **Loaded two files:**
   - `beach_monthly.csv`: 9,600 rows, 80 beaches × 120 months, Sep 2016 – Aug 2026.
   - `incidents.csv`: 33,941 rows, one per *person* involved.
2. **Collapsed people into incidents.** An incident can involve up to 3 people: 31,240 involve one, 956 involve two and 263 involve three. That gives **32,459 incidents**.
3. **Took the worst severity per incident**, ranking Mild < Close call < Severe. Only 211 incidents mixed severities, so the choice moves few numbers. Result: **28,997 mild, 3,242 close calls, 220 severe**.
4. **Counted by beach, month and severity**, and joined the counts onto the beach table.
5. **Filled empty months with 0.** A missing count means no incidents, not unknown. 39% of beach-months have no incidents at all, and 98% have no severe incident.

**Checks passed:** 9,600 rows, 32,459 incidents, and the severity totals match.

**Likely Q&A**
- **Why count incidents, not people?** Resources respond to incidents, and counting people double-counts one event. For severe it makes no difference: 220 severe people, 220 severe incidents.
- **Why the worst severity?** An incident is as serious as its worst outcome, and that matches Task 2's goal of minimising severe incidents.
- **Why beach × month?** That's the level the beach data comes in (visitors, weather, patrol hours). It's also the level funding decisions are made at: which beach, which months.
- **Why keep the zero months?** Without them the model only sees months where something happened and would overstate risk.
- **What's left out?** Person details (age, whether they were alone, swimming ability) and response time. Response time is only known after an incident happens, and none of these can be forecast for next year.

**What it sets up:** 98% of beach-months have no severe incident, the first sign that severe incidents are rare and lumpy. That's why later steps use a negative binomial model and quote ranges.

**On a slide:** "33,941 people → 32,459 incidents (worst outcome per incident) → 80 beaches × 120 months = 9,600 rows, each with mild, close-call and severe counts."

## 02 EDA: what the counts look like

**In one sentence:** before modelling, we checked how spread out the counts are, how they move with visitors, and how they change by season, year and beach. Each finding fixed one part of the model.

**1. The counts are overdispersed: they vary far more than a Poisson model allows**

| Per beach-month | Mean | Variance | % zero |
|---|---|---|---|
| All incidents | 3.38 | 45.9 | 39% |
| Mild | 3.02 | 38.6 | 41% |
| Close call | 0.34 | 0.86 | 81% |
| Severe | 0.023 | 0.027 | 98% |

- A Poisson model assumes variance = mean. Here the variance is more than 10 times the mean for mild incidents and all incidents.
- So a Poisson model would be far too confident. **Decision: negative binomial**, which adds a parameter for the extra spread.
- Severe is close to Poisson (0.027 vs 0.023), but with 98% zeros it is very sparse: about 22 events a year across 80 beaches. **Decision: quote ranges for severe, not exact numbers.**

**2. More visitors mean more incidents, but less than one-for-one**
- The slope of log(incidents) on log(visitors) is about 0.8 with no other predictors: doubling visitors raises incidents by about 75%, not 100%.
- **Decision:** model incidents *per visitor* (visitors as an offset), and test letting the data choose the slope instead (step 05). The free slope gained almost nothing out of sample, so we kept the simpler per-visitor model.

**3. Season: counts peak in summer, but risk per visit peaks in winter and spring**

| | Summer (Nov–Feb) | Mar–Oct | Winter (May–Aug) |
|---|---|---|---|
| Mild per 100k visits | 7.4 – 8.3 | 13 – 18 | 14 – 17 |
| Severe per 100k visits | 0.05 | 0.05 – 0.09 outside winter | 0.18 – 0.30 |

- January has the most visitors (48m over ten years) and the most mild incidents. Per visit, though, it is the safest time of year.
- A June visit is about **5–6 times more likely to end in a severe incident** than a January visit (0.30 vs 0.05 per 100k).
- Why: rougher seas, and patrols mostly run Sep–Apr (about 80% of beach-months patrolled, against 12% in May–Aug).
- **Decision:** month goes in the model. The month effects and the lifeguard effect share credit, because patrols follow the season. We state this as a caveat.

**4. Time: two things the model must handle**

| FY | Mild per 100k | Close calls per 100k | Severe per 100k |
|---|---|---|---|
| 2017–2019 | 11.7 – 12.0 | 1.7 – 1.9 | 0.11 – 0.15 |
| 2020–2021 | 9.7 | 0.8 – 1.0 | 0.06 |
| 2022–2026 | 10.6 – 12.3 | 0.9 – 1.3 | 0.06 – 0.09 |

- **The FY2020–21 dip:** mild incidents per visit fell about 20% and then recovered. The data doesn't say why (a reporting change? fewer risky visitors?). **Decision:** a flag (`period_2021`) for those two years, listed as a limitation.
- **Serious incidents per visit roughly halved after FY2019 and stayed down.** This is not a dip: close calls went from about 1.8 to about 1.0 per 100k visits, severe from about 0.12 to about 0.07. Over the same period drone hours grew from 0 (FY2017) to about 13,000 a year (FY2020) and 30,000 (FY2026). The model credits drones with fewer close calls and severe incidents (step 04), which fits this pattern. Keep the caveat: it lines up in time with the FY2020 dip, so the data can't separate the two cleanly.

**5. Beaches: big beaches have more incidents, but not only because they are big**
- Total incidents per beach move with visitors (correlation 0.86; 0.72 for severe).
- But incidents per 100k visits range from about 5 to 46 across beaches (median 13). Beaches with similar visitor numbers carry very different risk.
- **Seven Mile Beach (Lennox Head) is the standout:** 22 severe incidents over ten years, the most of any beach, from only 4.2m visits. That is 0.52 severe per 100k visits, about 5 times Bondi, North Wollongong or Byron.
- **Decision:** beach-level risk goes in the model, through measured traits (rips, rocks, shore length) or one effect per beach (step 05 tests both).

**Likely Q&A**
- **What does overdispersion mean, simply?** Some beach-months are much worse than average and many are quiet. The counts are lumpier than pure chance would give, so a model has to allow for that or it will understate the uncertainty.
- **Why look per visit, not raw counts?** Raw counts mostly show where the crowds are. Per-visit rates show where each visit is dangerous, and that is what safety spending can change.
- **Why is winter riskier if there are fewer incidents?** Fewer people go, but the seas are rougher and the beaches are mostly unpatrolled. Each person faces more risk.
- **Is the post-2019 fall in serious incidents real?** It is in the data and it persists for six years, so it isn't noise. Drones are the most likely candidate, and the model agrees, but it is an association, not proof.

**What it sets up:** negative binomial (overdispersion), visitors as exposure, month in the model (season), a flag for FY2020–21, and beach-level risk.

**On a slide:** "Summer has the crowds; winter has the risk. A June visit is about 5–6 times more likely than a January visit to end in a severe incident."

## 03 Features: choosing and transforming the predictors

**In one sentence:** we picked a small set of predictors that each have a clear story, dropped near-duplicates, and reshaped a few so their effect in the model makes sense.

### How to read a transformation in this model
The model works on the log scale: `log(expected incidents) = intercept + b1·x1 + b2·x2 + …`. So each predictor **multiplies** the expected count by `exp(b)` per unit of `x` (the rate ratio). A transformation changes what "one unit" means, and so how the effect is shaped.

### The transformations, one by one

**1. Visitors: `log(visitors)`, used as an offset**
- *What:* `log(visitors)` goes into the model with its coefficient fixed at 1. On the log scale, `log(expected) = log(visitors) + …` is the same as `expected = visitors × rate`.
- *Why:* visitors are exposure, not a risk factor. Twice the people at the same risk should give twice the incidents. The offset makes every other coefficient an effect on **incidents per visitor**.
- *Why the log:* visitors range from a few hundred to 458,000 per beach-month (median about 8,400). The log turns "× 2 visitors" into a fixed step.
- *Tested:* letting the data choose the slope instead of fixing it at 1 (the EDA slope was about 0.8). Out of sample it gained almost nothing (step 05), so we kept the simpler offset.

**2. Lifeguard and drone hours: `log(1 + hours)` (`log_lg`, `log_drone`)**
- *What:* `log1p(x) = log(1 + x)`. The "+1" keeps zero hours at zero (`log(0)` is undefined), and it is close to `log(x)` once hours are large.
- *Why zeros matter:* 42% of beach-months have no lifeguard hours and 77% have no drone hours. Plain `log` would break on these.
- *Why log at all:* hours are very skewed (lifeguards: median 280, top 1% about 2,900; drones: up to 150 a month). And we expect **diminishing returns**: the first 100 hours at an empty beach should matter more than going from 2,000 to 2,100.
- *How to read it:* each RR applies per **log unit**, which is about ×2.7 hours. Ten times the hours is 2.3 log units. Examples:
  - Severe incidents, lifeguards (RR 0.86): 100 → 1,000 hours gives 0.86^2.3 ≈ 0.71, about **29% fewer** severe incidents.
  - Severe incidents, drones (RR 0.76): 0 → 100 hours is about 4.6 log units, giving 0.76^4.6 ≈ 0.28, a **72% fall**.
- *Caveat (important for Task 2):* the step from **zero** to some hours is where `log1p` is steepest and the data is thinnest. This is why the first drone hours at an uncovered beach look extremely effective. Treat those results as optimistic.

**3. Month: `mon` as a factor (12 categories)**
- *What:* each calendar month gets its own effect, measured against January (11 parameters).
- *Why a factor, not a number:* risk doesn't rise in a straight line from January to December. It is low in summer, high in winter and spring. A factor lets each month be different without assuming a shape.
- *Cost:* 11 parameters. A summer/winter flag or a smooth curve would be cheaper, but with 9,600 rows we can afford it.
- *Caveat:* patrols are seasonal too, so month and lifeguard hours share credit.

**4. Financial year: `fy`**
- *What:* Sep–Aug years, labelled by the year they end, so FY2027 = Sep 2026 – Aug 2027.
- *Why:* the data runs Sep 2016 – Aug 2026, so this gives 10 complete years, and the forecast year is one whole FY. It is used for splitting and summaries, not as a predictor.

**5. FY2020–21 flag: `period_2021` (1 in those two years, else 0)**
- *Why:* the EDA showed a dip of about 20% in mild incidents per visit that the other inputs don't explain. Without the flag, the model would blur that dip into the other effects.
- *In the forecast:* set to 0 (we assume no repeat). Listed as a limitation: we can't explain the dip, so we can't rule out a repeat.

**6. Rips per km: `rips_per_km = n_rips / (shore_len_m / 1000)`**
- *Why density:* 3 rips on a 500 m beach is far more hazardous per swimmer than 3 rips along 4 km. Density says how likely a swimmer is to be near a rip.
- *It is different information:* rips per km and the raw rip count correlate only 0.48 across beaches. We use density, and keep shore length separately for beach size.
- *Range:* 0 to 7.1 per km (median 1.7). About 6% of beach-months are at beaches with no rips.

**7. Marine health: an ordered factor (L < M < H)**
- *What:* the order is kept, and R splits it into a straight-line trend from L to H (`.L`) and a bend (`.Q`, whether M sits off the line).
- *Why:* uses the order without assuming the step L→M equals M→H, and costs only 2 parameters.

**Kept as they are:** swell, wind days, rain, air temperature, campaign index (already 0–1), first aid coverage (0–100), PA, flags, equipment rating, rocky, fishing, rockpool, shore length, surfer share, tourist share. Their scales are already sensible, and leaving them untransformed keeps them easy to explain ("each extra metre of swell…").

### Variables we dropped, and why
Pairs that move together share credit and make effects unstable, so we kept one from each:

| Dropped | Too close to | Correlation | Kept because |
|---|---|---|---|
| Average swell | Max swell | 0.96 | the biggest waves are the hazard |
| Water temperature | Air temperature | 0.79 | air temperature drives who goes to the beach |
| Turbidity | Rain | 0.77 | turbidity is mostly a result of rain |
| Number of bins | Visitors | 0.76 | a proxy for beach size, already covered |
| Ice-cream visits | Air temperature | 0.72 | a proxy for hot days, already covered |
| Response time (incidents file) | — | — | only known after an incident, so it can't predict one |

### Likely Q&A
- **Why log the hours?** Two reasons: the hours are very skewed, and we expect diminishing returns. The tenth lifeguard on a beach adds less than the first.
- **Why `log(1 + x)` and not `log(x)`?** Most beach-months have zero drone hours, and `log(0)` is undefined. The "+1" keeps zero at zero.
- **Doesn't that exaggerate the first hours?** It can. The jump from 0 to 100 hours is large on the log scale. We flag this in Task 2 and don't rely on exact sizes there.
- **Why rips per km instead of number of rips?** It measures how likely a swimmer is to be near one. A long beach with a few rips is safer than a short one with the same number.
- **Why visitors as an offset rather than a predictor?** It makes everything else a per-visitor effect, which is what safety spending can change. Letting the slope vary didn't forecast better.
- **Why so few variables?** Every predictor has to be explainable to a non-technical panel, and near-duplicates make effects unstable without improving forecasts.

**On a slide:** a three-column table (input → transformation → why), e.g. "Lifeguard hours → log(1 + hours) → diminishing returns; many zeros".
