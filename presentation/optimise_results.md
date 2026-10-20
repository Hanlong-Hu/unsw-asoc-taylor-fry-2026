# part2/optimise.Rmd results (run 2026-10-20)

Run unchanged against `part1/panel.rds` and `part1/pricing.csv`. The Rmd reads `../pricing.csv`, so pricing had to be placed at the repo root for it to run. Solver: HiGHS, status success, ~6 s.

## Headline
- Baseline (Sep 2025 – Aug 2026 conditions, Poisson GLM): **19.3** severe incidents
- After the $2M plan: **6.7**, so **12.6 avoided (65%)**
- 90% range on avoided: **10.9–14.7** (2,000 draws of the GLM coefficients, allocation held fixed; coefficient uncertainty only)
- Cost per severe incident avoided: ~$159k

## Spend
| Initiative | Spend | Units |
|---|---|---|
| Community first aid & rescue training | $1,840,000 | 92 courses in 33 postcodes (62 beaches) |
| Drone operator hours | $85,000 | 1,889 hrs at 19 beaches that already fly drones |
| Education campaigns | $75,000 | 5 postcodes (11 beaches) |
| Lifeguards, drone hardware, PA, flags | $0 | |

Avoided by each initiative on its own: first aid 12.1, campaigns 0.8, drones 0.6. Beaches touched by any initiative: 73 of 80. Top 10 beaches by gain: 37% of the avoided total. May–Aug: 34%.

Top beaches by avoided incidents: Terrigal, Maroubra, Palm Beach, Mollymook, Byron Bay (Main Beach), Shelly Beach (Manly), Wamberal, Dee Why, Wanda, Coogee.

## Issues to resolve before the semi-final
1. **Lifeguard coefficient is positive** (+0.0005 per hour, p < 0.001), so the optimiser never buys lifeguards. The GLM has no visitor exposure, month or beach terms, so this is probably confounding (patrols go to busy beaches). It contradicts the Task 1 drivers slide and the Part 1 negative binomial model.
2. **First aid does 96% of the work.** At −0.043 per capacity point, 4 courses (+40) multiply risk by ~0.18. That effect size needs defending in Q&A, or a check against the Part 1 model.
3. **Baseline mismatch:** 19.3 here vs the FY2027 forecast of ≈ 21 (15–33) from Part 1.
4. `mip_rel_gap` is not accepted by the HiGHS plugin (a warning), so the 1% gap setting has no effect.
5. The alternatives (spread evenly, summer-only patrols, education only) are not computed by the Rmd; the slide still has `[__]` for them.
