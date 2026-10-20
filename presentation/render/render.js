// Render each slide at 1920x1080 in headless Chrome: a PNG per slide plus layout checks.
// Usage: node presentation/render/render.js [slide-id,slide-id,...]   (then sheets.js for contact sheets)
// The CSS below approximates the Slides format (icons and arrows are rough); use the real viewer for a final look.
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const DECK = path.join(__dirname, "..", "deck_artifact", "project");
const OUT = path.join(__dirname, "out");
const CHROME = process.env.CHROME || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
fs.mkdirSync(OUT, { recursive: true });
const only = process.argv[2] ? process.argv[2].split(",") : null;
const order = JSON.parse(fs.readFileSync(path.join(DECK, "deck.json"))).order;

const css = `
*{box-sizing:border-box;margin:0}
html,body{margin:0;background:#888;width:1920px;height:1080px;overflow:hidden}
section{width:1920px;height:1080px;position:relative;overflow:hidden;display:flex;flex-direction:column;font-family:Inter,Arial,sans-serif}
div{display:flex;flex-direction:column}
h1{font-size:96px;font-weight:600;line-height:1.1} h2{font-size:64px;font-weight:600;line-height:1.15}
h3{font-size:44px;font-weight:600;line-height:1.2} p{font-size:32px;line-height:1.4}
ul,ol{padding-left:1.2em} table{border-collapse:collapse} td,th{padding:0.35em 0.6em;border-bottom:1px solid #e5e7eb;text-align:left;vertical-align:top}
aside{display:none} x-shape,x-icon{display:block;flex:none}
x-shape[kind=arrow-right]{clip-path:polygon(0 30%,60% 30%,60% 0,100% 50%,60% 100%,60% 70%,0 70%)}
x-shape[kind=arrow-up]{clip-path:polygon(30% 100%,30% 40%,0 40%,50% 0,100% 40%,70% 40%,70% 100%)}
x-shape[kind=arrow-down]{clip-path:polygon(30% 0,70% 0,70% 60%,100% 60%,50% 100%,0 60%,30% 60%)}
x-icon{border-radius:50%;border:4px solid currentColor}
`;
const check = `
<script>
document.fonts.ready.then(()=>setTimeout(()=>{
  const s=document.querySelector('section'), out=[], S=s.getBoundingClientRect();
  const isPinned=e=>{for(let x=e;x&&x!==s;x=x.parentElement){if(getComputedStyle(x).position==='absolute')return true}return false};
  const txt=[...s.querySelectorAll('h1,h2,h3,p,li,td,th')].filter(e=>e.textContent.trim());
  const lab=e=>(e.tagName+' "'+e.textContent.trim().slice(0,40)+'"');
  if(s.scrollHeight>1081||s.scrollWidth>1921) out.push('SECTION overflows canvas: '+s.scrollWidth+'x'+s.scrollHeight);
  for(const e of txt){
    if(e.scrollWidth>e.clientWidth+2) out.push('TEXT too wide for its box ('+e.scrollWidth+' > '+e.clientWidth+'): '+lab(e));
    const r=document.createRange(); r.selectNodeContents(e); const rs=[...r.getClientRects()];
    if(!rs.length) continue;
    const b=Math.max(...rs.map(x=>x.bottom)), rt=Math.max(...rs.map(x=>x.right)), l=Math.min(...rs.map(x=>x.left));
    if(b>1080||rt>1920||l<0) out.push('TEXT off canvas (right '+Math.round(rt)+', bottom '+Math.round(b)+'): '+lab(e));
    else if(!isPinned(e) && b>921) out.push('FLOW text below y=920 (bottom '+Math.round(b)+'): '+lab(e));
    else if(rt>1793 && !isPinned(e)) out.push('TEXT past right margin (right '+Math.round(rt)+'): '+lab(e));
    e._r=rs;
  }
  // overlapping glyph boxes between different text elements
  for(let i=0;i<txt.length;i++)for(let j=i+1;j<txt.length;j++){
    const a=txt[i],c=txt[j]; if(!a._r||!c._r||a.contains(c)||c.contains(a))continue;
    if(a._r.some(x=>c._r.some(y=>x.left<y.right-1&&y.left<x.right-1&&x.top<y.bottom-1&&y.top<x.bottom-1)))
      out.push('OVERLAP: '+lab(a)+' with '+lab(c));
  }
  // boxes (painted divs) spilling past the canvas or the bottom margin
  for(const d of s.querySelectorAll('div,table,svg')){const r=d.getBoundingClientRect(); if(!r.width)continue;
    if(r.right>1921||r.bottom>1081) out.push('BOX off canvas ('+Math.round(r.right)+','+Math.round(r.bottom)+'): '+d.tagName+' '+(d.getAttribute('style')||'').slice(0,60));
    else if(!isPinned(d)&&r.bottom>922&&getComputedStyle(d).backgroundColor!=='rgba(0, 0, 0, 0)') out.push('BOX below y=920 (bottom '+Math.round(r.bottom)+'): '+(d.getAttribute('style')||'').slice(0,60));
  }
  const n=s.querySelectorAll('*').length; if(n>200) out.push('ELEMENTS '+n+' > 200');
  const pre=document.createElement('pre'); pre.id='__out'; pre.textContent=JSON.stringify(out); document.body.appendChild(pre); pre.style.display='none';
},300));
</script>`;

const report = {};
order.forEach((id, i) => {
  if (only && !only.includes(id)) return;
  const sec = fs.readFileSync(path.join(DECK, "slides", id + ".html"), "utf8");
  const html = `<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap">
<style>${css}</style></head><body>${sec}${check}</body></html>`;
  const f = path.join(OUT, `${String(i + 1).padStart(2, "0")}_${id}.html`);
  fs.writeFileSync(f, html);
  const base = ["--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1", "--window-size=1920,1080", "--virtual-time-budget=6000"];
  execFileSync(CHROME, [...base, `--screenshot=${f.replace(/\.html$/, ".png")}`, "file://" + f], { stdio: "ignore" });
  const dom = execFileSync(CHROME, [...base, "--dump-dom", "file://" + f], { encoding: "utf8", maxBuffer: 1 << 26 });
  const m = dom.match(/<pre id="__out"[^>]*>([\s\S]*?)<\/pre>/);
  report[`${i + 1} ${id}`] = m ? JSON.parse(m[1].replace(/&quot;/g, '"').replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">")) : ["(check did not run)"];
});
for (const [k, v] of Object.entries(report)) console.log(`\n## ${k}: ${v.length ? v.length + " issue(s)" : "ok"}\n` + v.map(x => "  - " + x).join("\n"));
