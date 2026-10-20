# Slide deck prompt (draft v1: outline)

Paste everything below the line into the slide tool. Values in `[[double brackets]]` are still to be filled from `part2/optimise.Rmd` once it has been run.

---

## 1. Context

You are designing a slide deck for the **2026 UNSW ASOC x Taylor Fry Actuarial Case Competition**.

- **Setting:** Taylor Fryland, a fictional coastal country modelled on NSW. 80 beaches, millions of visitors a year. The government already funds lifeguard patrols, drone surveillance, safety education and rescue infrastructure, but incidents still happen, mostly where safety coverage is thin.
- **Client question:** the government is considering an **extra $2M a year** for beach safety. Where should it go to **minimise severe incidents**?
- **Audience:** a judging panel from ASOC and Taylor Fry, role-playing **non-technical government officials**. They want a clear decision, not a methods lecture. Technical detail lives in the appendix for Q&A.
- **Format:** a **10-minute** talk, about 15 content slides plus dividers (35–40 seconds per slide), then Q&A. 16:9.
- **How it's marked:** Task 1 analysis 45%, Task 2 analysis 20%, clarity of the answers 10%, **presentation style 25%** (effective slides, coherent story).
- **Data:** ten years (Sep 2016 – Aug 2026) of monthly beach data, incident records and an initiative price list. No outside data is allowed.

## 2. Goal of the deck

By the last slide, the panel should be able to repeat three things:

1. **How many:** about 21 severe incidents are expected in FY2027 if nothing changes (90% range about 15–33), alongside about 3,600 mild incidents and 316 close calls.
2. **Where and when:** severe risk is concentrated. The top 10 beaches hold about half of it, and a winter visit is 4–7 times riskier than a summer one because the seas are rougher and patrols mostly stop.
3. **What to do:** spend the $2M on `[[main initiatives]]` at `[[N]]` high-risk beaches, avoiding about `[[X]]` severe incidents a year, with a 12-month review.

Every slide should move one of these three forward. If it doesn't, it goes in the appendix.

## 3. Visual direction

**Colour palette: blue and white**

| Role | Hex | Use for |
|---|---|---|
| Primary blue | `#5D7BCC` | dark slide backgrounds (title, dividers, close), title text on white, big numbers, the main chart series |
| Secondary blue | `#5F79C9` | panel fills, chart series 2, lines, icons, step circles |
| White | `#FFFFFF` | background of every content slide; text on blue |
| Deep navy (derived) | `#1F2A4D` | body text on white, and the **one highlighted** bar, beach or month in a chart |
| Pale blue (derived) | `#EEF2FB` | cards, table banding, the "so what" box |
| Grey (derived) | `#6B7280` | captions, sources, axis labels, "everything else" in charts |

Notes on the palette:
- `#5D7BCC` and `#5F79C9` are almost the same colour, so they can't separate two chart series on their own. Contrast in charts comes from **blue vs grey vs navy**, or from light and dark tints of the blue (e.g. `#5D7BCC` at 100% and 40%).
- White text on `#5D7BCC` has a contrast ratio of about 4:1. Use it only for large text (titles, 18 pt bold and up, big numbers). Body text sits on white in navy.
- No other hues. "Risk up" and "risk down" are shown with direction, labels and navy vs light blue, not red and green.

**Typography:** a clean sans serif throughout (e.g. Calibri or Inter). Titles 28–36 pt, body at least 14 pt, captions 10–12 pt. Big numbers 60–80 pt in primary blue.

**Layout rules**
- **Sandwich structure:** blue slides open, divide and close; every content slide is white.
- **Title = the message, not the topic.** "Summer has the crowds; winter has the risk", not "Seasonality".
- **One message per slide.** A small uppercase kicker above the title says where we are (`TASK 1 · FORECAST`, `TASK 2 · ALLOCATION`).
- **Severe numbers always carry a range:** "≈ 21 (15–33)", never a bare point.
- Generous white space, left-aligned text, no clip art, no gradients, no drop shadows. One simple motif: a thin blue bar or a blue numbered circle.
- **Charts:** white background, main series in `#5D7BCC`, the rest in grey, one highlight in navy. Label values directly instead of using a legend. Light or no gridlines.

## 4. Outline

### Opening
1. **Title** *(blue)*: "Spending $2M where it prevents the most severe beach incidents". Subtitle: one-line recommendation. Team name, members, date.
2. **Executive summary** *(three big-number cards + "so what" box)*: ≈ 21 severe incidents expected (15–33) → top 10 beaches hold ~50% / winter visits 4–7× riskier → `[[X]]` fewer severe incidents with the $2M plan. The box gives the recommendation in one sentence.
3. **The brief** *(two columns, optional)*: Task 1 "How many, where and when?" vs Task 2 "Where should $2M go?" Title: "Goal: fewest severe incidents for $2M a year".

### Task 1: Forecast
4. **Divider** *(blue)*: "1 · Forecasting next year's incidents".
5. **From raw data to a forecastable table** *(four steps)*: 33,941 people → 32,459 incidents → 80 beaches × 120 months → 9,600 beach-months with counts by severity.
6. **Summer has the crowds; winter has the risk** *(chart + takeaway)*: monthly visitors (grey bars) vs severe incidents per 100k visits (blue line), June in navy. Takeaway: a June visit is ~5–6× riskier than a January one; ~80% of beach-months are patrolled in summer vs ~12% in winter.
7. **How the model works** *(simple table: input → how we used it → why)*: visitors as exposure, lifeguard and drone hours with diminishing returns, month, rips per km, beach risk. One line: negative binomial model per severity.
8. **Tested on years it hadn't seen** *(chart + takeaway)*: rolling-origin test results; XGBoost as the challenger didn't beat it; the FY2026 backtest landed inside the range.
9. **FY2027 forecast** *(three big numbers)*: Mild ~3,600 · Close calls ~316 · Severe ~21 (15–33). Box: "Plan on the range, not the point."
10. **Where and when** *(heatmap: top 20 beaches × month)*: name 2–3 standouts (e.g. North Wollongong, top for severe at ~2 a year; Seven Mile Beach, ~5× Bondi's risk per visit). May–Aug holds ~44% of severe risk.
11. **What drives severe incidents** *(rate-ratio dot chart)*: risk factors vs protective factors, with lifeguards and drones in navy because Task 2 pulls those levers. Caveat: association, not proof.

### Task 2: Allocation
12. **Divider** *(blue)*: "2 · Allocating the extra $2M".
13. **The recommendation** *(hero slide)*: the $2M split by initiative (stacked bar) plus a big number, "≈ `[[X]]` fewer severe incidents a year". Funded beaches as small chips underneath.
14. **How we chose** *(four steps)*: baseline risk (Task 1) → price every option → estimate what each dollar removes → pick the best mix within $2M.
15. **Why this, not the alternatives** *(two columns or cost-per-incident-avoided bars)*: what we fund vs what we didn't (spread evenly, summer-only patrols, education-only), with cost per severe incident avoided.
16. **Implementation** *(timeline by quarter of FY2027)*: hire and train before winter, deploy drones, and track severe incidents at funded beaches with a 12-month review.

### Close
17. **Assumptions and limitations** *(two columns)*: visitors +1.9%/yr, weather like the past decade, safety at FY2026 levels | association not causation, severe events are rare, the FY2020–21 dip is unexplained, the first drone hours may be optimistic.
18. **Conclusion** *(blue)*: three numbered takeaways plus the ask: "Approve the $2M plan for FY2027 with a 12-month review". Stays on screen during Q&A.

### Appendix (white, denser)
A1 Model specification · A2 Validation detail · A3 Forecast uncertainty (simulation) · A4 Optimisation formulation · A5 Pricing inputs.

## 5. What to deliver at this stage

The **structure and visual system only**: master layouts in the palette above, every slide with its message title and placeholder boxes where the charts go, and speaker-note stubs. Real charts and the Task 2 numbers come in the next pass.
