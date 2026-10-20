const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
// Contact sheets of four slides each from render.js output (needs ImageMagick's `magick`).
const dir = path.join(__dirname, "out");
const pngs = fs.readdirSync(dir).filter(f => /^\d\d_.*\.png$/.test(f)).sort();
for (let i = 0; i < pngs.length; i += 4) {
  const files = pngs.slice(i, i + 4).map(f => path.join(dir, f));
  const out = path.join(dir, `sheet${i / 4 + 1}.png`);
  while (files.length < 4) files.push(files[files.length - 1]);
  execFileSync("/opt/homebrew/bin/magick", ["(", files[0], files[1], "+append", ")", "(", files[2], files[3], "+append", ")",
    "-append", "-resize", "50%", out]);
  console.log(out, pngs.slice(i, i + 4).join(" "));
}
