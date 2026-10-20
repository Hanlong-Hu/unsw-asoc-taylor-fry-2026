# part2/optimise.Rmd results (Part 1 model, run 2026-10-20)

The optimiser now uses the Part 1 severe model (`part1/forecast_fy2027.rds`: negative binomial, visitors offset, `log1p` lifeguard and drone hours), and its FY2027 forecast is the baseline. The earlier version used a separate Poisson GLM with no exposure, month or beach terms; it found lifeguards harmful and put 92% of the budget into first aid.

Solver: HiGHS called directly with a 1% gap; it finished Optimal at a 0.6% gap in about 1 minute. Effects are recomputed exactly from the hours bought.

## Headline
- Baseline FY2027: **21.4** expected severe incidents (simulated 90% range 15–33, median 23, matching Part 1)
- With the plan: **9.0**, so **12.5 avoided (58%)**
- Expected avoided, 90% range: **11–16** (5,000 simulated years: weather, parameters; allocation fixed)
- Severe incidents in a year with the plan: 4–16 (90%), median 9
- Cost per severe incident avoided: **~$160k**

## Spend
| Initiative | Spend | Units | Avoided on its own |
|---|---|---|---|
| Drone flight hours | $908,255 | 20,183 hrs (9,935 at beaches with drones, 10,248 at new ones) | |
| Drone hardware + operator training | $255,150 | 27 new drones | drones total 8.4 |
| Casual lifeguards (winter patrols) | $391,595 | 6,752 hrs at 22 beaches, May–Aug, blocks of ≥ 97 hrs/month | 2.1 |
| Education campaigns | $330,000 | 22 postcodes (42 beaches), Nov–Feb | 2.7 |
| Rip-warning flags | $115,000 | 23 beaches | 2.1 |
| Full-time lifeguards, first aid, PA | $0 | | |

69 of 80 beaches funded. Top 10 beaches: 53% of the avoided total. May–Aug: 50%.

Top beaches by avoided incidents: North Wollongong, Seven Mile Beach (Lennox Head), Copacabana, Byron Bay (Main Beach), Kiama Surf Beach, Terrigal, Mollymook, Mona Vale, Bondi, Maroubra.

## Alternatives (same model and baseline)
| Option | Spend | Avoided | $ per avoided |
|---|---|---|---|
| Optimised plan | $2.0M | 12.5 | ~$160k |
| Education only (every postcode that can use one) | $615k | 2.9 | ~$209k |
| Spread evenly ($25k casual lifeguard hours per beach) | $2.0M | 3.0 | ~$656k |
| Summer-only patrols (Nov–Feb, by visitors) | $1.93M | 0.3 | ~$5.6M |

## Modelling choices to be able to defend
1. **Log-gain formulation.** The decision variables are `log1p` gains, so the incident effect is linear in them. The hours they need are convex and are modelled with chord lines, so cost is never understated. `exp()` uses tangent lines, as before.
2. **Minimum patrol block = 97 hrs/month** (5th percentile of patrolled months). Without it, `log1p` lets the solver spread 1–10 hour patrols over hundreds of unpatrolled months (median 8 hrs). The block costs only 0.3 avoided incidents (12.8 → 12.5).
3. **First aid and PA are not bought**: their coefficients are at or above zero for severe incidents in the Part 1 model.
4. **Drones dominate** (8.4 of 12.5) because `log_drone` is −0.26 and most beaches fly no drones; the first drone hours at a new beach count heavily. This is the main limitation to raise in Q&A ("the first drone hours may be optimistic").
5. Effects are associations. Lifeguards and drones were probably placed where risk is high, so their effects may be understated.
