// Kade pastel themes — 6 palettes × light/dark. Each maps to CSS custom properties consumed by inline styles.
export const THEMES = [
  { id: 'hong', name: 'Hồng phấn', light: { bg: '#FBEEF1', sf: '#FFFFFF', sf2: '#FDE4EA', tx: '#2B1E24', mu: '#7A6570', ac: '#D97A93', acT: '#9B4560', ac1: '#FCE6EC', ac2: '#F6C7D4', on: '#FFFFFF', b: '#7FA38E', bT: '#3F6B54', b1: '#E1EFE7', off: '#FFE1DC', offT: '#B23A3A', sun: '#C4544F', line: '#EED3DB', sh: 'rgba(90,40,60,.10)' },
    dark: { bg: '#1D171B', sf: '#2A2127', sf2: '#372A33', tx: '#F5E9EE', mu: '#B39AA6', ac: '#F0A5B8', acT: '#F7C6D3', ac1: '#3E2A34', ac2: '#573545', on: '#2B1E24', b: '#9DC1AE', bT: '#BFDACB', b1: '#26332C', off: '#4A2B2B', offT: '#F3A6A0', sun: '#F09A96', line: '#3F3138', sh: 'rgba(0,0,0,.35)' } },
  { id: 'mint', name: 'Xanh mint', light: { bg: '#EBF6F1', sf: '#FFFFFF', sf2: '#DDF1E8', tx: '#1B2A25', mu: '#5E7A70', ac: '#5EB39A', acT: '#2C7560', ac1: '#DCF2EA', ac2: '#BDE6D6', on: '#FFFFFF', b: '#E0A56B', bT: '#8F5A22', b1: '#FBEBDA', off: '#FFE1DC', offT: '#B23A3A', sun: '#C4544F', line: '#CFE5DB', sh: 'rgba(30,80,60,.10)' },
    dark: { bg: '#141C19', sf: '#1E2925', sf2: '#28362F', tx: '#E8F3EE', mu: '#93AEA3', ac: '#8FD6BE', acT: '#B4E6D5', ac1: '#233A32', ac2: '#2F4E42', on: '#132A22', b: '#F0BF8C', bT: '#F6D4B0', b1: '#3A2E20', off: '#4A2B2B', offT: '#F3A6A0', sun: '#F09A96', line: '#2E3D37', sh: 'rgba(0,0,0,.35)' } },
  { id: 'bien', name: 'Xanh biển', light: { bg: '#EDF3FA', sf: '#FFFFFF', sf2: '#DFEAF7', tx: '#1B2533', mu: '#61728A', ac: '#6E9BD8', acT: '#33619F', ac1: '#E1EBF8', ac2: '#C4D8F2', on: '#FFFFFF', b: '#D9A56A', bT: '#8A5A1E', b1: '#FBEBD8', off: '#FFE1DC', offT: '#B23A3A', sun: '#C4544F', line: '#D2DFEE', sh: 'rgba(30,60,100,.10)' },
    dark: { bg: '#141920', sf: '#1D2530', sf2: '#27313F', tx: '#E9EFF7', mu: '#94A5BC', ac: '#9EC0EE', acT: '#BFD6F5', ac1: '#23303F', ac2: '#2E4158', on: '#12203A', b: '#EFC08C', bT: '#F6D5B1', b1: '#3A2F20', off: '#4A2B2B', offT: '#F3A6A0', sun: '#F09A96', line: '#2D3846', sh: 'rgba(0,0,0,.35)' } },
  { id: 'lavender', name: 'Tím lavender', light: { bg: '#F2EFFA', sf: '#FFFFFF', sf2: '#E7E1F7', tx: '#241F33', mu: '#6F6786', ac: '#9A88D6', acT: '#5E4B9E', ac1: '#EBE6F9', ac2: '#D7CDF3', on: '#FFFFFF', b: '#E5A88F', bT: '#95552F', b1: '#FBE8E0', off: '#FFE1DC', offT: '#B23A3A', sun: '#C4544F', line: '#DDD6EE', sh: 'rgba(60,40,100,.10)' },
    dark: { bg: '#18151F', sf: '#221E2C', sf2: '#2D2839', tx: '#EEEAF7', mu: '#A79EBD', ac: '#BBAEEB', acT: '#D1C8F3', ac1: '#2C263D', ac2: '#3C3452', on: '#1F1838', b: '#F2BFA9', bT: '#F7D4C5', b1: '#3B2C26', off: '#4A2B2B', offT: '#F3A6A0', sun: '#F09A96', line: '#352F44', sh: 'rgba(0,0,0,.35)' } },
  { id: 'dao', name: 'Cam đào', light: { bg: '#FCF0E8', sf: '#FFFFFF', sf2: '#FBE3D6', tx: '#2E221B', mu: '#846A5C', ac: '#E8956E', acT: '#A5552F', ac1: '#FCE6DA', ac2: '#F8CFBA', on: '#FFFFFF', b: '#8AA27D', bT: '#4C6640', b1: '#E6EEDF', off: '#FFE1DC', offT: '#B23A3A', sun: '#C4544F', line: '#F0D7C9', sh: 'rgba(110,60,30,.10)' },
    dark: { bg: '#1E1714', sf: '#2A211C', sf2: '#382B24', tx: '#F7ECE5', mu: '#B99E90', ac: '#F4B597', acT: '#F8CDB8', ac1: '#3E2B22', ac2: '#55392C', on: '#2E1A10', b: '#B2C7A4', bT: '#CDDCC3', b1: '#2C3527', off: '#4A2B2B', offT: '#F3A6A0', sun: '#F09A96', line: '#413129', sh: 'rgba(0,0,0,.35)' } },
  { id: 'kem', name: 'Kem be ấm', light: { bg: '#F5EAD8', sf: '#FFFBF4', sf2: '#EBDDC5', tx: '#201E1D', mu: '#6F665B', ac: '#CF8B5C', acT: '#8C491A', ac1: '#FFF2EB', ac2: '#FFE1D0', on: '#FFFFFF', b: '#7A8A5E', bT: '#56633F', b1: '#E1EECC', off: '#FFE1DC', offT: '#B23A3A', sun: '#C4544F', line: '#DCD3C4', sh: 'rgba(46,43,37,.12)' },
    dark: { bg: '#1C1916', sf: '#28241F', sf2: '#352F28', tx: '#F4ECE0', mu: '#B4A793', ac: '#F0B486', acT: '#F6CBA8', ac1: '#3A2E23', ac2: '#4F3D2D', on: '#2E1E10', b: '#AEBF92', bT: '#CCDBB2', b1: '#2E3322', off: '#4A2B2B', offT: '#F3A6A0', sun: '#F09A96', line: '#3D362E', sh: 'rgba(0,0,0,.35)' } },
];
export const KIND = { vnHoliday: '#D65B5B', vnMemorial: '#E0913F', international: '#5B8DD6', personal: '#9B6BC9' };
export const KIND_DARK = { vnHoliday: '#F2A0A0', vnMemorial: '#F3C08C', international: '#A6C4F0', personal: '#CDB0EA' };
export const USER = ['#9B6BC9', '#3FA8B3', '#5EAE6A', '#D9709A', '#7F6DD6', '#3E9E8F', '#B5B03A', '#9C7A66'];
export function cssVars(themeId, dark) {
  const t = THEMES.find(x => x.id === themeId) || THEMES[0], p = dark ? t.dark : t.light, out = {};
  for (const k in p) out['--' + k] = p[k];
  return out;
}
