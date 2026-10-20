# Slide design notes

Companion to `deck_design.pptx`. The deck holds only the design: layouts, empty placeholders and sections. These are suggestions for how to fill each slide. Slide numbers match the deck. Every slide's speaker notes point back here.

## The design system

**Colours** (set in the PowerPoint theme, so the theme colour picker offers them):

The palette comes from a bright geometric mural: vivid blue leads, sunny yellow highlights, and red, pink and green add energy.

| Role | Hex | Use for |
|---|---|---|
| Bright blue (primary) | `0F79D5` | dark slide backgrounds, titles, big numbers, the main chart series |
| Sunny yellow (secondary) | `F4B223` | badges, pills, the **one** highlighted bar or beach in a chart |
| Red | `E0251B` | second chart series; "bad" direction (risk up) |
| Pink | `E2558F` | third chart series, step arrows |
| Green | `2E8B1E` | fourth chart series; "good" direction (risk down) |
| Ink | `16151F` | body text, and any text on yellow (blue on yellow is too faint) |
| Pale blue | `E7F1FB` | cards and panels on white slides |
| Pale pink | `FCE9F2` | the "so what" box |
| White | `FFFFFF` | background of content slides, text on blue |
| Grey | `5B6B7A` | captions, sources, axis labels, "other" series |

Orange (`E8590F`) and light pink (`F2B6E3`) appear only in the decorative blocks.

**Rule of thumb:** blue and white carry most of the weight. Yellow is the highlight. Red, pink and green go in charts and only where a series needs its own colour. The colourful blocks are the excitement, so keep the content slides clean and don't use more than three colours in one chart.

**Text contrast:** white on blue, ink on yellow, blue or ink on white. Never put yellow text on white or on blue.

**Fonts:** Cambria (headings, big numbers) and Calibri (body). Both ship with Office, so nothing moves on another laptop.

**Motif:** overlapping colour blocks taken from the mural: a tall panel on the right of the title slide, and a band along the bottom of the dividers and the closing slide. Yellow circles and pills (section numbers, step numbers, column badges, the kicker pill above each title) carry it onto the white slides. Keep icons or numbers inside the yellow circles. Don't add other decoration.

**Sandwich structure:** dark slides open, divide and close; everything in between is white.

## Layouts

Pick these from **Home → Layout** when you add a slide.

| Layout | Placeholders | Best for |
|---|---|---|
| Title (dark) | title, subtitle, meta | cover |
| Section divider (dark) | number (yellow circle), title, subtitle | Task 1 / Task 2 / Appendix openers |
| Three stats | kicker, title, 3 × (big number + label), "so what" box | headline numbers |
| Chart + takeaway | kicker, title, picture area (left), takeaway panel (right), source | any chart |
| Two columns | kicker, title, 2 × (heading + points) | comparisons |
| Four steps | kicker, title, 4 × (heading + text), numbered circles | processes, methods, rollouts |
| Table | kicker, title, table, source | tables |
| Title only | kicker, title, free body | custom compositions |
| Closing (dark) | title, body, yellow "ask" box | conclusion |
| Appendix | pale pill, smaller title, body | backup slides for Q&A |

## Rules for every content slide

- **Kicker pill:** 1–3 words in capitals naming the section (`TASK 1 · FORECAST`, `TASK 2 · ALLOCATION`). It tells the panel where they are.
- **Title is the message, not the topic.** "Summer has the crowds; winter has the risk", not "Seasonality". No full stop at the end.
- **One message per slide.** If you need two takeaways, it's two slides.
- **Charts:** export from R at about 7.9" × 4.4" (the picture area on Chart + takeaway) with a white background. Use blue `0F79D5` for the main series, grey `5B6B7A` (or red/pink/green when series need telling apart) for the rest, and yellow `F4B223` for the one thing you want them to look at. Use Calibri, grey axis labels, light or no gridlines, and label values directly instead of using a legend where you can. Use the same text sizes on every chart.
- **Severe numbers get a range:** "≈ NN (low–high)", never a bare point.
- **Text sizes:** body at least 14 pt, captions 10–12 pt. If it doesn't fit, cut words.
- **Technical detail goes in the appendix.** The panel is told to imagine non-technical officials.

## Slide by slide

Timing: 10 minutes over 15 content slides plus 2 quick dividers is about 35–40 seconds a slide. If rehearsal runs long, move **slide 3** (The brief) and **slide 14** (How we chose) to the appendix first.

### Opening

**1. Title** (*Title (dark)*)
- Title: the outcome, e.g. "Spending $2M where it saves the most lives at the beach".
- Subtitle: the one-line recommendation.
- Meta: team name, members, date. Nothing else; the colour panel on the right does the work.

**2. Executive summary** (*Three stats*)
- Three cards, read left to right as the story: **forecast** (expected severe incidents in FY2027 with a range) → **where/when** (e.g. "top 10 beaches hold ~45% of severe risk", or "winter visits ~5–6× riskier") → **impact** (severe incidents avoided by the $2M plan).
- "So what" box: the recommendation in one sentence.
- If the panel only remembers one slide, it's this one.

**3. The brief** (*Two columns*): optional
- Left: "Task 1: how many incidents next year, where and when?" Right: "Task 2: where should the extra $2M go?"
- 2–3 short points each. Put the objective in the title: "Goal: fewest severe incidents for $2M a year".

### Task 1: Forecast

**4. Task 1 divider** (*Section divider*): number `1`, title "Forecasting next year's incidents", subtitle "How many, where and when".

**5. From raw data to beach-months** (*Four steps*)
- 1 "33,941 people" → 2 "32,459 incidents (worst outcome each)" → 3 "80 beaches × 120 months" → 4 "9,600 rows, counts by severity".
- Make the big number the step heading and put one line of explanation underneath.

**6. Summer crowds, winter risk** (*Chart + takeaway*)
- Chart: two panels or a combo chart by month: visitors (grey bars) vs severe incidents per 100k visits (blue line), with **June highlighted in yellow**.
- Takeaway: "A June visit is ~5–6× more likely to end in a severe incident than a January visit." Points: rougher seas, about 12% of winter beach-months patrolled vs about 80% in summer.

**7. How the model works** (*Table*)
- Three columns: **Input → How we used it → Why**. 5–6 rows: visitors (per-visitor rate), lifeguard and drone hours (log, diminishing returns), month (each month its own effect), rips per km (density near swimmers), beach (own effect for mild; traits for rare severities).
- One line above or in the source: "Negative binomial GLM, one per severity". Detail goes in A1.
- Table style: blue header row with white text, pale blue banding, no vertical lines.

**8. Model chosen on unseen years** (*Chart + takeaway*)
- Chart: predicted vs actual severe (or all) incidents for each rolling-origin test year, or a bar chart of out-of-sample log score by candidate model with the chosen one in yellow. XGBoost appears as the challenger.
- Takeaway: "Chosen on five years it had never seen." Points: XGBoost didn't beat it; calibration 1.00 for severe; top 10 beaches hold ~45% of severe incidents vs 12.5% at random.

**9. FY2027 forecast by severity** (*Three stats*)
- Cards: Mild, Close calls, Severe, each a big number with a range in the label and a comparison ("vs 26 in FY2026").
- "So what": severe incidents are rare and lumpy; plan on the range, not the point.

**10. Where and when** (*Chart + takeaway*)
- Chart: a heatmap of the top 15–20 beaches (rows) × month (columns), shaded white → blue (or white → red to say "danger"), with the riskiest cells labelled. A simple shaded map of the coast with circles sized by expected severe incidents also works.
- Takeaway: name 2–3 beaches (e.g. Seven Mile Beach, Lennox Head: 0.52 severe per 100k visits, ~5× Bondi) and the risky months.

**11. What drives severe incidents** (*Chart + takeaway*)
- Chart: horizontal dot or bar chart of rate ratios with a vertical line at 1. Risk factors to the right in red, protective factors to the left in green, **drones and lifeguards in yellow** because they are the levers Task 2 pulls.
- Takeaway: translate into plain words: "100 drone hours at an uncovered beach is linked to far fewer severe incidents". Caveat in the last point: association, not proof.

### Task 2: Allocation

**12. Task 2 divider** (*Section divider*): number `2`, title "Allocating the extra $2M", subtitle "Which beaches, which initiatives".

**13. Recommendation: the $2M allocation** (*Title only*)
- The most important Task 2 slide. Suggested composition: left two-thirds a horizontal stacked bar or "budget waterfall" of the $2M by initiative (drones, lifeguards, flags, PA, campaign, first aid). Right third a yellow-ringed big number: "≈ X fewer severe incidents a year".
- Underneath: the top 5 funded beaches as small pale-blue chips.
- Title states the recommendation, e.g. "Put most of the $2M into drones and winter patrols at 12 high-risk beaches".

**14. How we chose the allocation** (*Four steps*)
- 1 "Forecast baseline risk (Task 1)" → 2 "Price every option (pricing file)" → 3 "Estimate what each purchase removes (the GLM)" → 4 "Pick the best mix within $2M (optimiser)".
- Keep the maths out; MILP detail goes in A4.

**15. Why this, not the alternatives** (*Two columns*)
- Left heading "What we fund": each item with its cost per severe incident avoided. Right heading "What we didn't, and why": e.g. spreading money evenly, summer-only patrols, an education campaign (low effect per dollar).
- A cost-per-incident-avoided bar chart in place of the right column works well if the numbers are striking.

**16. Implementation** (*Table*)
- Columns: **When · What · Who / risk**. Rows by quarter of FY2027 (hiring and drone training before winter, etc.).
- Add a monitoring row: "Track severe incidents at funded beaches; review after 12 months".

### Close

**17. Assumptions and limitations** (*Two columns*)
- Left "Assumptions": visitors +1.9%/yr, safety at FY2026 levels, weather like the last 10 years, no FY2020–21 dip repeat.
- Right "Limitations": association not cause, severe events rare (~20/yr), unexplained FY2020–21 dip, optimistic first drone hours (log1p), no external data.
- Put an icon in each yellow circle (✓ for assumptions, ! for limitations).

**18. Conclusion** (*Closing (dark)*)
- Title: restate the main message.
- Body: three numbered takeaways (forecast, where/when, allocation).
- Yellow box: the decision you want, e.g. "Approve the $2M plan for FY2027, with a 12-month review". Leave this slide up during Q&A.

### Appendix

**19. Appendix divider**: number `A`, title "Appendix", subtitle "Detail for questions".

Appendix slides use the *Appendix* layout: smaller title, denser content is fine. Change the layout of any of them to *Chart + takeaway* or *Table* if that fits better.

- **A1 Model specification:** formula per severity, offset, chosen spec (M6 beach effects for mild, M5 traits for close calls and severe), dropped variables and correlations.
- **A2 Validation detail:** rolling-origin log scores, the single-split table, XGBoost comparison.
- **A3 Forecast uncertainty:** simulation method (weather replays, NB draws), ranges by severity, the FY2026 backtest.
- **A4 Optimisation formulation:** decision variables, budget and capacity constraints (2 FTE per beach, 120 drone hrs/month, etc.), tangent-line approximation, solver gap.
- **A5 Pricing inputs:** the pricing table as used, with amortisation assumptions.

## Rebuilding the design

`build_deck.js` generates the deck. To change a colour or font for every slide, edit `HEX`/`THEME` at the top and run:

```bash
NODE_PATH=<folder with pptxgenjs and sharp installed> PPTX_SKILL=<pptx skill folder> node presentation/build_deck.js
```

It overwrites `deck_design.pptx`, so only rebuild before you start filling it in. After that, change colours in PowerPoint through **Design → Variants → Colors**, which follow the theme.
