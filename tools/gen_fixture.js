const a = require('../docs/reference/amlich-aa98.js');
const TZ = 7;
function jd(dd,mm,yy){ // proleptic gregorian via same formula
  const A=Math.floor((14-mm)/12), y=yy+4800-A, m=mm+12*A-3;
  return dd+Math.floor((153*m+2)/5)+365*y+Math.floor(y/4)-Math.floor(y/100)+Math.floor(y/400)-32045;
}
function fromJd(j){ const d=new Date(Date.UTC(2000,0,1)); d.setUTCDate(d.getUTCDate()+(j-2451545)); return [d.getUTCDate(), d.getUTCMonth()+1, d.getUTCFullYear()]; }
const out = {};
for (let y=1900; y<=2100; y++){
  const [td,tm,ty] = a.convertLunar2Solar(1,1,y,0,TZ);
  const [nd,nm,ny] = a.convertLunar2Solar(1,1,y+1,0,TZ);
  const j0 = jd(td,tm,ty), j1 = jd(nd,nm,ny);
  const months = []; let leap = 0; let cur=null;
  for (let j=j0;j<j1;j++){
    const [d,m,yy] = fromJd(j);
    const [ld,lm,ly,ll] = a.convertSolar2Lunar(d,m,yy,TZ);
    const key = lm+(ll?'L':'');
    if (cur!==key){ months.push({m:lm, leap:!!ll, days:0, start:`${yy}-${String(m).padStart(2,'0')}-${String(d).padStart(2,'0')}`}); cur=key; if(ll) leap=lm; }
    months[months.length-1].days++;
  }
  out[y] = { tet:`${ty}-${String(tm).padStart(2,'0')}-${String(td).padStart(2,'0')}`, leapMonth: leap, daysInYear: j1-j0, months };
}
require('fs').writeFileSync(__dirname + '/../docs/reference/tet_1900_2100.json', JSON.stringify({ source:'generated from amlich-aa98.js (Ho Ngoc Duc), timeZone +7', generatedAt: new Date().toISOString().slice(0,10), years: out }, null, 1));
for (const y of [1900,1968,1984,1985,2007,2024,2025,2026,2027,2028,2029,2030,2033,2100]) console.log(y, out[y].tet, 'leap', out[y].leapMonth, 'days', out[y].daysInYear);
