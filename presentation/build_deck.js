// Builds the empty slide-deck design (layouts + placeholders, no content).
// Run: NODE_PATH=<dir with pptxgenjs + sharp> node presentation/build_deck.js
// Colours and fonts live in THEME; change them here and rebuild to restyle every slide.

const path = require("path");
const pptxgen = require("pptxgenjs");
const sharp = require("sharp");
const { applyTheme } = require(process.env.PPTX_SKILL + "/scripts/apply_theme.js");

const OUT = process.env.OUT || path.join(__dirname, "deck_design.pptx");

// Palette: deep ocean blue (primary), sandy yellow (secondary), white.
const HEX = {
  ocean: "0A3D62",     // primary: backgrounds of dark slides, titles, big numbers
  deep: "072B45",      // darker ocean: text on light slides
  sea: "2E7DA6",       // lighter ocean: second chart series, links
  mist: "EAF1F6",      // very pale ocean: cards and panels on white slides
  sand: "E9C46A",      // secondary: badges, pills, highlight series
  sandDeep: "B8902E",  // darker sand: highlight text that must read on white
  sandPale: "FBF3DC",  // pale sand: "so what" boxes
  grey: "5B6B7A",      // captions, footers
  white: "FFFFFF",
};

const THEME = {
  name: "Ocean and Sand",
  headFontFace: "Cambria",
  bodyFontFace: "Calibri",
  colors: {
    dk1: HEX.deep, lt1: HEX.white, dk2: HEX.ocean, lt2: HEX.mist,
    accent1: HEX.ocean, accent2: HEX.sand, accent3: HEX.sea,
    accent4: HEX.sandDeep, accent5: "8FB8D3", accent6: HEX.grey,
    hlink: HEX.sea, folHlink: HEX.grey,
  },
};

const W = 13.333, H = 7.5, M = 0.6; // LAYOUT_WIDE, outer margin

// Waves along the bottom of the dark slides: the deck's one decorative motif.
async function wavePng() {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="2667" height="400" viewBox="0 0 2667 400">
    <path d="M0 170 C 300 90, 600 250, 950 170 S 1600 90, 1950 175 S 2450 250, 2667 160 L2667 400 L0 400 Z" fill="#${HEX.sea}" fill-opacity="0.35"/>
    <path d="M0 250 C 350 180, 700 320, 1100 245 S 1800 170, 2200 250 S 2550 300, 2667 240 L2667 400 L0 400 Z" fill="#${HEX.deep}"/>
    <path d="M0 250 C 350 180, 700 320, 1100 245 S 1800 170, 2200 250 S 2550 300, 2667 240" fill="none" stroke="#${HEX.sand}" stroke-width="6"/>
  </svg>`;
  const buf = await sharp(Buffer.from(svg)).png().toBuffer();
  return "image/png;base64," + buf.toString("base64");
}

async function build() {
  const pres = new pptxgen();
  pres.layout = "LAYOUT_WIDE";
  pres.title = "Beach safety: forecast and $2M allocation";
  pres.subject = "UNSW ASOC x Taylor Fry Case Competition 2026";
  pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
  const C = pres.SchemeColor;
  const WAVE = await wavePng();
  // Layouts only accept rect/text/image/line objects, so cards and badges are empty shaped text boxes.
  const shape = (type, opts) => ({ text: { text: "", options: { shape: pres.ShapeType[type], line: { type: "none" }, ...opts } } });

  const footer = (dark) => ([
    { text: { text: "UNSW ASOC x Taylor Fry Case Competition 2026", options: {
      x: M, y: H - 0.5, w: 6, h: 0.3, fontSize: 10, color: dark ? C.background1 : C.accent6, margin: 0 } } },
  ]);
  const slideNumber = (dark) => ({ x: W - M - 0.6, y: H - 0.5, w: 0.6, h: 0.3, fontSize: 10,
    color: dark ? HEX.sand : HEX.grey, align: "right" });

  // Title, kicker pill and footer shared by every light content layout.
  const kickerPill = (fill) => shape("roundRect", { x: M, y: 0.45, w: 2.6, h: 0.36, rectRadius: 0.18, fill: { color: fill } });
  const kicker = (prompt) => ({ placeholder: { options: { name: "kicker", type: "body", x: M, y: 0.45, w: 2.6, h: 0.36,
    fontSize: 11, bold: true, color: C.text2, align: "center", valign: "middle", charSpacing: 1.5, margin: 0 }, text: prompt } });
  const title = (size = 32) => ({ placeholder: { options: { align: "left", name: "title", type: "title", x: M, y: 0.95, w: W - 2 * M, h: 0.9,
    fontSize: size, bold: true, color: C.text2, valign: "top", margin: 0 }, text: "Action title: the one message of this slide" } });
  const lightBase = (pillFill, kickerPrompt, titleSize) => [kickerPill(pillFill), kicker(kickerPrompt), title(titleSize), ...footer(false)];
  const TOP = 2.05, BOTTOM = H - 0.85; // content zone on light slides

  // ---------- Layouts ----------
  pres.defineSlideMaster({
    title: "Title (dark)", background: { color: HEX.ocean }, objects: [
      { image: { x: 0, y: H - 1.5, w: W, h: 1.5, data: WAVE } },
      { placeholder: { options: { align: "left", name: "title", type: "title", x: M + 0.2, y: 1.7, w: 9.5, h: 1.8, fontSize: 44, bold: true,
        color: C.background1, valign: "bottom", margin: 0 }, text: "Presentation title" } },
      { placeholder: { options: { align: "left", name: "subtitle", type: "body", x: M + 0.2, y: 3.65, w: 9.5, h: 0.6, fontSize: 20,
        color: C.accent2, margin: 0 }, text: "Subtitle: the recommendation in one line" } },
      { placeholder: { options: { align: "left", name: "meta", type: "body", x: M + 0.2, y: 4.6, w: 9.5, h: 0.8, fontSize: 14,
        color: C.background1, margin: 0 }, text: "Team name · member names · date" } },
    ],
  });

  pres.defineSlideMaster({
    title: "Section divider (dark)", background: { color: HEX.ocean }, objects: [
      { image: { x: 0, y: H - 1.5, w: W, h: 1.5, data: WAVE } },
      shape("ellipse", { x: M + 0.2, y: 2.35, w: 1.3, h: 1.3, fill: { color: HEX.sand } }),
      { placeholder: { options: { name: "number", type: "body", x: M + 0.2, y: 2.35, w: 1.3, h: 1.3, fontSize: 40, bold: true,
        fontFace: THEME.headFontFace, color: C.text2, align: "center", valign: "middle", margin: 0 }, text: "1" } },
      { placeholder: { options: { align: "left", name: "title", type: "title", x: M + 1.9, y: 2.25, w: 9, h: 0.95, fontSize: 40, bold: true,
        color: C.background1, valign: "bottom", margin: 0 }, text: "Section title" } },
      { placeholder: { options: { align: "left", name: "subtitle", type: "body", x: M + 1.9, y: 3.25, w: 9, h: 0.55, fontSize: 18,
        color: C.accent2, margin: 0 }, text: "The question this section answers" } },
      ...footer(true),
    ], slideNumber: slideNumber(true),
  });

  pres.defineSlideMaster({
    title: "Title only", background: { color: HEX.white }, objects: [
      ...lightBase(HEX.sand, "SECTION", 32),
      { placeholder: { options: { align: "left", name: "body", type: "body", x: M, y: TOP, w: W - 2 * M, h: BOTTOM - TOP, fontSize: 16,
        color: C.text1, valign: "top" }, text: "Free canvas: build cards, diagrams or tables here" } },
    ], slideNumber: slideNumber(false),
  });

  // Chart or picture on the left, takeaway panel on the right.
  const panelX = 8.85, panelW = W - M - panelX;
  pres.defineSlideMaster({
    title: "Chart + takeaway", background: { color: HEX.white }, objects: [
      ...lightBase(HEX.sand, "SECTION", 32),
      { placeholder: { options: { align: "left", name: "chart", type: "pic", x: M, y: TOP, w: panelX - M - 0.35, h: BOTTOM - TOP - 0.4,
        color: C.text1 }, text: "Insert chart (paste or picture)" } },
      { placeholder: { options: { align: "left", name: "source", type: "body", x: M, y: BOTTOM - 0.3, w: panelX - M - 0.35, h: 0.3, fontSize: 10,
        italic: true, color: C.accent6, margin: 0 }, text: "Source / note" } },
      shape("roundRect", { x: panelX, y: TOP, w: panelW, h: BOTTOM - TOP, rectRadius: 0.12, fill: { color: HEX.mist } }),
      { placeholder: { options: { align: "left", name: "takeaway_head", type: "body", x: panelX + 0.3, y: TOP + 0.3, w: panelW - 0.6, h: 0.9,
        fontSize: 20, bold: true, fontFace: THEME.headFontFace, color: C.text2, valign: "top", margin: 0 }, text: "Key takeaway" } },
      { placeholder: { options: { align: "left", name: "takeaway", type: "body", x: panelX + 0.3, y: TOP + 1.35, w: panelW - 0.6, h: BOTTOM - TOP - 1.65,
        fontSize: 15, color: C.text1, valign: "top", margin: 0, paraSpaceAfter: 8 }, text: "Two or three short supporting points" } },
    ], slideNumber: slideNumber(false),
  });

  // Three big-number cards with a "so what" box underneath.
  const cardW = (W - 2 * M - 2 * 0.35) / 3, cardH = 2.75;
  const statObjs = [];
  for (let i = 0; i < 3; i++) {
    const x = M + i * (cardW + 0.35);
    statObjs.push(
      shape("roundRect", { x, y: TOP, w: cardW, h: cardH, rectRadius: 0.12, fill: { color: HEX.mist } }),
      { placeholder: { options: { align: "left", name: `stat${i + 1}`, type: "body", x: x + 0.3, y: TOP + 0.3, w: cardW - 0.6, h: 1.2, fontSize: 54, bold: true,
        fontFace: THEME.headFontFace, color: C.text2, valign: "bottom", margin: 0 }, text: "00" } },
      { placeholder: { options: { align: "left", name: `label${i + 1}`, type: "body", x: x + 0.3, y: TOP + 1.6, w: cardW - 0.6, h: 0.95, fontSize: 15,
        color: C.text1, valign: "top", margin: 0 }, text: "What the number means" } },
    );
  }
  const soY = TOP + cardH + 0.35;
  pres.defineSlideMaster({
    title: "Three stats", background: { color: HEX.white }, objects: [
      ...lightBase(HEX.sand, "SECTION", 32), ...statObjs,
      shape("roundRect", { x: M, y: soY, w: W - 2 * M, h: BOTTOM - soY, rectRadius: 0.12, fill: { color: HEX.sandPale } }),
      { placeholder: { options: { align: "left", name: "sowhat", type: "body", x: M + 0.3, y: soY + 0.15, w: W - 2 * M - 0.6, h: BOTTOM - soY - 0.3,
        fontSize: 16, color: C.text1, valign: "middle", margin: 0 }, text: "So what: what this means for the government" } },
    ], slideNumber: slideNumber(false),
  });

  // Two side-by-side cards (comparison, assumptions vs limitations, chosen vs rejected).
  const colW = (W - 2 * M - 0.4) / 2;
  const colObjs = [];
  [0, 1].forEach((i) => {
    const x = M + i * (colW + 0.4);
    colObjs.push(
      shape("roundRect", { x, y: TOP, w: colW, h: BOTTOM - TOP, rectRadius: 0.12, fill: { color: HEX.mist } }),
      shape("ellipse", { x: x + 0.3, y: TOP + 0.3, w: 0.5, h: 0.5, fill: { color: HEX.sand } }),
      { placeholder: { options: { align: "left", name: `col${i + 1}_head`, type: "body", x: x + 0.95, y: TOP + 0.3, w: colW - 1.25, h: 0.5, fontSize: 20, bold: true,
        fontFace: THEME.headFontFace, color: C.text2, valign: "middle", margin: 0 }, text: "Column heading" } },
      { placeholder: { options: { align: "left", name: `col${i + 1}`, type: "body", x: x + 0.3, y: TOP + 1.05, w: colW - 0.6, h: BOTTOM - TOP - 1.35,
        fontSize: 15, color: C.text1, valign: "top", margin: 0, paraSpaceAfter: 8 }, text: "Points for this column" } },
    );
  });
  pres.defineSlideMaster({
    title: "Two columns", background: { color: HEX.white }, objects: [...lightBase(HEX.sand, "SECTION", 32), ...colObjs],
    slideNumber: slideNumber(false),
  });

  // Four numbered steps left to right (data pipeline, optimisation method, rollout).
  const stepW = (W - 2 * M - 3 * 0.35) / 4;
  const stepObjs = [];
  for (let i = 0; i < 4; i++) {
    const x = M + i * (stepW + 0.35);
    stepObjs.push(
      shape("roundRect", { x, y: TOP + 0.45, w: stepW, h: BOTTOM - TOP - 0.45, rectRadius: 0.12, fill: { color: HEX.mist } }),
      shape("ellipse", { x: x + stepW / 2 - 0.45, y: TOP, w: 0.9, h: 0.9, fill: { color: HEX.sand }, line: { color: HEX.white, width: 3 } }),
      { text: { text: String(i + 1), options: { x: x + stepW / 2 - 0.45, y: TOP, w: 0.9, h: 0.9, fontSize: 26, bold: true,
        fontFace: THEME.headFontFace, color: C.text2, align: "center", valign: "middle", margin: 0 } } },
      { placeholder: { options: { align: "left", name: `step${i + 1}_head`, type: "body", x: x + 0.25, y: TOP + 1.1, w: stepW - 0.5, h: 0.8, fontSize: 18, bold: true,
        fontFace: THEME.headFontFace, color: C.text2, align: "center", valign: "top", margin: 0 }, text: "Step heading" } },
      { placeholder: { options: { align: "left", name: `step${i + 1}`, type: "body", x: x + 0.25, y: TOP + 2.0, w: stepW - 0.5, h: BOTTOM - TOP - 2.3,
        fontSize: 14, color: C.text1, valign: "top", margin: 0 }, text: "What happens in this step" } },
    );
    if (i < 3) stepObjs.push({ text: { text: "›", options: { x: x + stepW - 0.02, y: TOP + 2.6, w: 0.39, h: 0.6, fontSize: 32,
      bold: true, color: C.accent4, align: "center", valign: "middle", margin: 0 } } });
  }
  pres.defineSlideMaster({
    title: "Four steps", background: { color: HEX.white }, objects: [...lightBase(HEX.sand, "SECTION", 32), ...stepObjs],
    slideNumber: slideNumber(false),
  });

  pres.defineSlideMaster({
    title: "Table", background: { color: HEX.white }, objects: [
      ...lightBase(HEX.sand, "SECTION", 32),
      { placeholder: { options: { align: "left", name: "table", type: "tbl", x: M, y: TOP, w: W - 2 * M, h: BOTTOM - TOP - 0.45, color: C.text1 },
        text: "Insert table" } },
      { placeholder: { options: { align: "left", name: "source", type: "body", x: M, y: BOTTOM - 0.3, w: W - 2 * M, h: 0.3, fontSize: 10,
        italic: true, color: C.accent6, margin: 0 }, text: "Source / note" } },
    ], slideNumber: slideNumber(false),
  });

  pres.defineSlideMaster({
    title: "Closing (dark)", background: { color: HEX.ocean }, objects: [
      { image: { x: 0, y: H - 1.5, w: W, h: 1.5, data: WAVE } },
      { placeholder: { options: { align: "left", name: "title", type: "title", x: M + 0.2, y: 0.9, w: W - 2 * M - 0.4, h: 1.0, fontSize: 40, bold: true,
        color: C.background1, valign: "bottom", margin: 0 }, text: "Closing message" } },
      { placeholder: { options: { align: "left", name: "body", type: "body", x: M + 0.2, y: 2.25, w: 8.2, h: 3.4, fontSize: 18,
        color: C.background1, valign: "top", margin: 0, paraSpaceAfter: 10 }, text: "Three recommendations to remember" } },
      shape("roundRect", { x: 9.3, y: 2.25, w: W - M - 9.5, h: 2.4, rectRadius: 0.12, fill: { color: HEX.sand } }),
      { placeholder: { options: { align: "left", name: "ask", type: "body", x: 9.55, y: 2.45, w: W - M - 10.0, h: 2.0, fontSize: 18, bold: true,
        fontFace: THEME.headFontFace, color: C.text2, valign: "middle", margin: 0 }, text: "The decision we are asking for" } },
    ], slideNumber: slideNumber(true),
  });

  pres.defineSlideMaster({
    title: "Appendix", background: { color: HEX.white }, objects: [
      ...lightBase(HEX.mist, "APPENDIX", 28),
      { placeholder: { options: { align: "left", name: "body", type: "body", x: M, y: TOP, w: W - 2 * M, h: BOTTOM - TOP, fontSize: 14,
        color: C.text1, valign: "top" }, text: "Technical detail for Q&A" } },
    ], slideNumber: slideNumber(false),
  });

  // ---------- Slides (empty placeholders only) ----------
  const LAYOUT_PHS = {
    "Title (dark)": ["title", "subtitle", "meta"],
    "Section divider (dark)": ["number", "title", "subtitle"],
    "Title only": ["kicker", "title", "body"],
    "Chart + takeaway": ["kicker", "title", "takeaway_head", "takeaway", "source"],
    "Three stats": ["kicker", "title", "stat1", "label1", "stat2", "label2", "stat3", "label3", "sowhat"],
    "Two columns": ["kicker", "title", "col1_head", "col1", "col2_head", "col2"],
    "Four steps": ["kicker", "title", "step1_head", "step1", "step2_head", "step2", "step3_head", "step3", "step4_head", "step4"],
    "Table": ["kicker", "title", "source"],
    "Closing (dark)": ["title", "body", "ask"],
    "Appendix": ["kicker", "title", "body"],
  };
  // [section, layout, slide name] — slide names match presentation/slide_design_notes.md
  const PLAN = [
    ["Opening", "Title (dark)", "Title"],
    ["Opening", "Three stats", "Executive summary"],
    ["Opening", "Two columns", "The brief"],
    ["Task 1: Forecast", "Section divider (dark)", "Task 1 divider"],
    ["Task 1: Forecast", "Four steps", "From raw data to beach-months"],
    ["Task 1: Forecast", "Chart + takeaway", "Summer crowds, winter risk"],
    ["Task 1: Forecast", "Table", "How the model works"],
    ["Task 1: Forecast", "Chart + takeaway", "Model chosen on unseen years"],
    ["Task 1: Forecast", "Three stats", "FY2027 forecast by severity"],
    ["Task 1: Forecast", "Chart + takeaway", "Where and when"],
    ["Task 1: Forecast", "Chart + takeaway", "What drives severe incidents"],
    ["Task 2: Allocation", "Section divider (dark)", "Task 2 divider"],
    ["Task 2: Allocation", "Title only", "Recommendation: the $2M allocation"],
    ["Task 2: Allocation", "Four steps", "How we chose the allocation"],
    ["Task 2: Allocation", "Two columns", "Why this, not the alternatives"],
    ["Task 2: Allocation", "Table", "Implementation"],
    ["Close", "Two columns", "Assumptions and limitations"],
    ["Close", "Closing (dark)", "Conclusion"],
    ["Appendix", "Section divider (dark)", "Appendix divider"],
    ["Appendix", "Appendix", "A1 Model specification"],
    ["Appendix", "Appendix", "A2 Validation detail"],
    ["Appendix", "Appendix", "A3 Forecast uncertainty"],
    ["Appendix", "Appendix", "A4 Optimisation formulation"],
    ["Appendix", "Appendix", "A5 Pricing inputs"],
  ];

  let current = null;
  PLAN.forEach(([section, layout, name], i) => {
    if (section !== current) { pres.addSection({ title: section }); current = section; }
    const slide = pres.addSlide({ masterName: layout, sectionTitle: section });
    // QA=1 writes each placeholder's name into it, to check positions in a render
    LAYOUT_PHS[layout].forEach((ph) => slide.addText(process.env.QA ? `[${ph}]` : "", { placeholder: ph }));
    slide.addNotes(`Slide ${i + 1}: ${name}. Design suggestions: presentation/slide_design_notes.md`);
  });

  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log("wrote", OUT);
}

build().catch((e) => { console.error(e); process.exit(1); });
