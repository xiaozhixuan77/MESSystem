// extract-icons-production.mjs — production 模块专用图标生成
// 用法：在 MES/FrontEnd 目录运行 npm install sharp && node tools/extract-icons-production.mjs
import sharp from 'sharp';
import { writeFileSync, mkdirSync, existsSync } from 'fs';
import { join } from 'path';

// ============ 配置区 ============

const OUT_DIR = 'features/production/src/main/resources/base/media';
const SIZE = 200;

const BLUE = '#1890ff';
const GRAY = '#9A9AA8';
const WHITE = '#FFFFFF';
const GREEN = '#52c41a';
const ORANGE = '#fa8c16';
const RED = '#f5222d';

const paths = {
  'chevron-left': 'M19 12H5m7 7l-7-7 7-7',
  play: 'M5 3l14 9-14 9V3z',
  pause: 'M6 4h4v16H6z M14 4h4v16h-4z',
  reset: 'M23 4 L23 10 L17 10 M20.49 15a9 9 0 1 1-2.12-9.36L23 10',
  'alert-circle': 'M22 12 A10 10 0 0 0 2 12 A10 10 0 0 0 22 12z M12 8 L12 12 M12 16 L12.01 16',
  'line-icon': 'M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z M9 3 L9 21',
  filter: 'M4 21 L4 14 M4 10 L4 3 M12 21 L12 12 M12 8 L12 3 M20 21 L20 16 M20 12 L20 3 M1 14 L7 14 M9 8 L15 8 M17 16 L23 16',
};

const icons = [
  { file: 'icon_arrow_left_white', path: 'chevron-left', color: WHITE },
  { file: 'icon_arrow_left_gray', path: 'chevron-left', color: GRAY },
  { file: 'icon_play_white', path: 'play', color: WHITE },
  { file: 'icon_play_green', path: 'play', color: GREEN },
  { file: 'icon_stop_white', path: 'pause', color: WHITE },
  { file: 'icon_stop_orange', path: 'pause', color: ORANGE },
  { file: 'icon_reset_white', path: 'reset', color: WHITE },
  { file: 'icon_reset_blue', path: 'reset', color: BLUE },
  { file: 'icon_alert_white', path: 'alert-circle', color: WHITE },
  { file: 'icon_alert_red', path: 'alert-circle', color: RED },
  { file: 'icon_line_white', path: 'line-icon', color: WHITE },
  { file: 'icon_filter_gray', path: 'filter', color: GRAY },
];

async function main() {
  if (!existsSync(OUT_DIR)) {
    mkdirSync(OUT_DIR, { recursive: true });
  }

  let ok = 0;
  let fail = 0;
  for (const icon of icons) {
    const d = paths[icon.path];
    if (!d) {
      console.error(`MISSING path "${icon.path}" for ${icon.file}.png`);
      fail++;
      continue;
    }

    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="${icon.color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="${d}"/></svg>`;

    try {
      const png = await sharp(Buffer.from(svg))
        .resize(SIZE, SIZE, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
        .png()
        .toBuffer();

      const outPath = join(OUT_DIR, `${icon.file}.png`);
      writeFileSync(outPath, png);
      console.log(`  [${icon.color}] ${icon.file}.png (${png.length} bytes)`);
      ok++;
    } catch (e) {
      console.error(`FAIL: ${icon.file}.png — ${e.message}`);
      fail++;
    }
  }
  console.log(`\nDone. ${ok} ok, ${fail} fail, ${icons.length} total.`);
}

main();
