# Timeline Plan (MOCK-UP) — ASOC x Taylor Fry 2026

**Slides due: Thu 22 Oct (EOD). Heats start Thu 29 Oct.**
Q&A prep and rehearsal happen *after* submission (23–28 Oct), not before.

| Date | Phase | Goal | Output |
|---|---|---|---|
| Thu 15 – Sat 17 | **Individual exploration** | Each member explores and fits models independently (see expectations below) | Each member: 1-page summary + script/notebook, shared by Sat night |
| **Sun 18** | **Team sync** | Compare findings, choose the approach, split work | Agreed approach, owners, interim deadlines |
| Mon 19 | **Build** | Task 1 final model; Task 2 allocation logic in parallel | Task 1 forecast; Task 2 draft allocation |
| Tue 20 | **Analysis freeze (evening)** | Lock numbers, assumptions, limitations | Final numbers, charts, storyline bullets |
| Wed 21 | **Slides day 1** | Build body deck; technical detail to appendix | Full draft deck |
| Thu 22 | **Slides day 2 + submit** | Polish, timing check (10 min), email submission | Submitted deck + model files |
| Fri 23 – Wed 28 | **Q&A prep and rehearsal** | Hard-question brainstorm, assign answerers, 2+ timed run-throughs | Q&A cheat sheet, rehearsed delivery |
| Thu 29 → | **Heats** | Present and answer Q&A | — |

---

## 1. Individual exploration (Thu 15 – Sat 17): what each person does

All three of you explore on your own first. To make Sunday useful, everyone does the **same starting checklist** (so your results can be compared), plus **one different job each** (so you don't all end up with the same thing).

### The starting checklist (everyone, in this order)
1. **Look at the data.** Open the three files. How many rows? Anything missing or strange? Read the data dictionary.
2. **Count the incidents.** How many per year, per month, per beach, and per severity (mild / close call / severe)? Which beaches and months are worst?
3. **Build one simple prediction.** Use the first 9 years to predict the last year (Sep 2025 – Aug 2026), then check how close you got. Everyone uses that same last year so the models can be compared fairly.
4. **Find what matters.** What goes with more incidents? What goes with more *severe* incidents? Look at weather, visitor numbers, lifeguards, patrol hours, drones.
5. **Write down your assumptions** and anything odd you found in the data.

### Each person's extra job (suggested)
| Person | Your extra job | In plain terms |
|---|---|---|
| **Han** | **Predicting how many incidents** | Build the best model for "how many incidents will each beach have each month next year?" Check it against the held-out year. This answers Task 1, part 1. |
| **Aiden** | **Understanding severe incidents** | Work out what makes an incident severe rather than mild. Do beaches with more lifeguards or drones have fewer severe incidents? What are the causes and who is involved? This answers Task 1, part 2. |
| **Sunny** | **Costs and options** | Read the pricing file. What does each safety option cost and what does it do? What can $2M buy? Which beaches have the least coverage today? This sets up Task 2. Sunny also does the simple prediction from step 3 so they can follow Task 1. |

You can swap these if someone prefers a different one. You've already done a lot of the "predicting incidents" and "severity" work in `analysis/NOTES.md`, so Han could share that on Friday to save Aiden and Sunny some time.

### Agree in the group chat on Thursday
- Everyone uses the **same held-out year** (Sep 2025 – Aug 2026).
- Everyone saves results as simple CSV files and PNG charts in their own folder.
- Everyone posts a quick message on Friday night: "here's what I've found / here's where I'm stuck".

### What to send the group by Saturday night (one page each)
- Your best model, in one or two sentences, and how well it predicted the held-out year
- The 3–5 things that matter most for incidents, and the top 3 for severe incidents
- 2–3 charts you'd want to show the others
- The thing that surprised you most, and one question you couldn't answer
- Any problems or oddities in the data

---

## 2. Sun 18 team meeting (~90 min)
1. 5 min each: findings, model, surprise (15 min)
2. Compare models on the same holdout; agree **one** Task 1 approach (20 min)
3. Agree the driver story for Task 1.2: conditions vs lifeguards / patrol hours / drones (15 min)
4. Task 2 framing: objective, cost per initiative, constraints, how Task 1 feeds it (20 min)
5. Split roles for Mon–Tue; agree interim check-ins (15 min)
6. Consolidate assumptions and limitations list (5 min)

## 3. Mon–Tue build (suggested split after Sunday)
- **Task 1 (45% of marks):** finalise frequency + severity models, forecast by severity, where/when, driver analysis. Two people.
- **Task 2 (20%):** allocation of $2M across beaches and initiatives, alternatives rejected, implementation considerations. One person, using Task 1 outputs. Agree the interface on Sunday (e.g. predicted severe incidents per beach per month, and an effect-size assumption per initiative).
- **Tue evening freeze:** no new modelling after this; only presentation work.

## 4. Slides (Wed–Thu)
- Audience: non-technical government officials. Plain language, charts over text, speak to the slides.
- Body (~8–10 slides): exec summary → problem → Task 1 forecast → where/when → drivers → Task 2 recommendation → why best use of funds / alternatives rejected → implementation → assumptions and limitations.
- Technical detail (model specs, diagnostics) goes in the **appendix**.
- Wed: full draft by evening. Thu AM: polish + timing check. Thu PM: email (to careers@asoc.unsw.edu.au, subject `Taylor Fry Case Competition – [Team Name]`, team name and members in the body).

## 5. Post-submission: Q&A and rehearsal (Fri 23 – Wed 28)
- Brainstorm the hardest judge questions (model choice, assumptions, allocation logic); assign who answers what.
- Everyone able to explain every part of the solution.
- At least two timed 10-minute run-throughs with mock Q&A.
- Use any feedback from earlier rounds to revise the deck if allowed.

## 6. Risks
- Only ~3 days between Sunday and the analysis freeze: decide the approach Sunday and don't reopen it.
- Task 2 depends on Task 1 outputs: agree the interface Sunday.
- Three independent explorations can diverge: the common holdout and metric names are what make Sunday productive.
