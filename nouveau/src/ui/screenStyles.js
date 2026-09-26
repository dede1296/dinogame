// Styles for the menu windows (team, bag, journal, main menu): floating smoked-glass
// panels over the dimmed game, with a warm amber accent.

export const SCREEN_CSS = `
.hud { --s-bg: rgba(17,20,27,0.86); --s-card: rgba(255,255,255,0.045); --s-card-hi: rgba(255,255,255,0.08);
  --s-line: rgba(255,255,255,0.09); --s-text: #f3f1ec; --s-mute: rgba(243,241,236,0.62);
  --s-accent: #f5b942; --s-accent-2: #ff8a3d; --s-radius: 22px; }

/* While a menu window is open, the game controls are hidden. */
.hud.screen-open .topbtns, .hud.screen-open .pad, .hud.screen-open .btns { display: none; }

.scr { position: absolute; inset: 0; pointer-events: auto; display: flex; align-items: center; justify-content: center;
  padding: calc(16px + env(safe-area-inset-top)) 16px calc(16px + env(safe-area-inset-bottom));
  background: rgba(6,8,12,0.45); backdrop-filter: blur(3px); -webkit-backdrop-filter: blur(3px); animation: scr-fade 0.18s ease-out; }
.scr-win { width: min(440px, 100%); max-height: min(720px, 100%); display: flex; flex-direction: column; color: var(--s-text);
  background: linear-gradient(180deg, rgba(30,34,44,0.92), var(--s-bg)); border: 1px solid var(--s-line); border-radius: var(--s-radius);
  box-shadow: 0 24px 60px rgba(0,0,0,0.55), inset 0 1px 0 rgba(255,255,255,0.07); backdrop-filter: blur(18px) saturate(1.3); -webkit-backdrop-filter: blur(18px) saturate(1.3);
  padding: 16px; animation: scr-pop 0.22s cubic-bezier(0.16, 1, 0.3, 1); }
@keyframes scr-fade { from { opacity: 0; } to { opacity: 1; } }
@keyframes scr-pop { from { opacity: 0; transform: translateY(14px) scale(0.97); } to { opacity: 1; transform: none; } }
@media (prefers-reduced-motion: reduce) { .scr, .scr-win { animation: none; } }

.scr-head { display: flex; align-items: center; justify-content: space-between; margin: 0 2px 12px; }
.scr-head h2 { margin: 0; font-size: 19px; font-weight: 700; letter-spacing: 0.2px; display: flex; align-items: center; gap: 10px; }
.scr-ic { width: 34px; height: 34px; display: grid; place-items: center; font-size: 18px; border-radius: 11px;
  background: linear-gradient(135deg, rgba(245,185,66,0.25), rgba(255,138,61,0.12)); border: 1px solid rgba(245,185,66,0.3); }
.scr-ic img { width: 28px; height: 28px; }
.scr-x { width: 36px; height: 36px; border-radius: 50%; background: var(--s-card); border: 1px solid var(--s-line); color: var(--s-mute); font-size: 15px; cursor: pointer; transition: background 0.15s, color 0.15s; }
.scr-x:hover { background: var(--s-card-hi); color: var(--s-text); }
.scr-body { flex: 1; min-height: 0; overflow-y: auto; -webkit-overflow-scrolling: touch; display: flex; flex-direction: column; gap: 8px; scrollbar-width: thin; }
.scr-empty { color: var(--s-mute); text-align: center; padding: 28px 10px; line-height: 1.5; }
.scr-hint { font-size: 12.5px; color: var(--s-mute); text-align: center; padding: 2px 8px; }

/* Type and status pills */
.tag { display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px; border-radius: 999px; font-size: 10.5px; font-weight: 700; letter-spacing: 0.6px; margin: 0 4px 0 0; }

/* Team cards */
.pcard { display: grid; grid-template-columns: 76px 1fr; gap: 12px; align-items: center; padding: 10px 12px; border-radius: 16px; cursor: pointer; text-align: left;
  background: var(--s-card); border: 1px solid var(--s-line); color: inherit; font: inherit; transition: background 0.15s, border-color 0.15s, transform 0.1s; }
.pcard:hover, .pcard:focus-visible { background: var(--s-card-hi); border-color: rgba(255,255,255,0.18); outline: none; }
.pcard:active { transform: scale(0.99); }
.pcard.lead { background: linear-gradient(120deg, rgba(245,185,66,0.16), rgba(255,255,255,0.03) 60%); border-color: rgba(245,185,66,0.45); }
.pcard.ko { opacity: 0.55; filter: grayscale(0.7); }
.pcard.pick { border-color: var(--s-accent); box-shadow: 0 0 0 3px rgba(245,185,66,0.25); }
.pcard .pic { width: 76px; height: 58px; display: grid; place-items: center; border-radius: 12px; background: radial-gradient(ellipse at 50% 70%, rgba(255,255,255,0.09), rgba(255,255,255,0) 70%); }
.pcard .pic img { max-width: 74px; max-height: 54px; filter: drop-shadow(0 3px 4px rgba(0,0,0,0.4)); }
.pcard .nm { display: flex; justify-content: space-between; align-items: baseline; gap: 8px; font-weight: 700; font-size: 15.5px; }
.pcard .nm small { font-weight: 600; font-size: 12px; color: var(--s-mute); }
.pcard .sp { font-size: 12px; color: var(--s-mute); margin: 1px 0 6px; }
.lead-badge { font-size: 10px; font-weight: 700; letter-spacing: 0.8px; color: var(--s-accent); text-transform: uppercase; margin-left: 6px; }
.hpbar { display: flex; align-items: center; gap: 8px; margin-top: 7px; font-size: 10px; font-weight: 700; letter-spacing: 0.8px; color: var(--s-mute); }
.hpbar .bar { flex: 1; height: 6px; border-radius: 999px; background: rgba(255,255,255,0.08); overflow: hidden; }
.hpbar .bar i { display: block; height: 100%; border-radius: 999px; transition: width 0.4s ease; }
.hpnum { font-size: 11.5px; color: var(--s-mute); text-align: right; margin-top: 3px; font-variant-numeric: tabular-nums; }

/* Summary */
.sum-top { display: grid; grid-template-columns: 120px 1fr; gap: 14px; align-items: center; padding: 14px; border-radius: 18px;
  background: radial-gradient(ellipse at 20% 60%, rgba(245,185,66,0.14), rgba(255,255,255,0.03) 65%); border: 1px solid var(--s-line); }
.sum-top img { width: 120px; max-height: 90px; object-fit: contain; filter: drop-shadow(0 6px 8px rgba(0,0,0,0.45)); }
.sum-top h3 { margin: 0; font-size: 19px; font-weight: 700; }
.sum-sec { padding: 12px 14px; border-radius: 16px; background: var(--s-card); border: 1px solid var(--s-line); }
.sum-sec h4 { margin: 0 0 10px; font-size: 11px; font-weight: 700; letter-spacing: 1.6px; color: var(--s-mute); text-transform: uppercase; }
.sum-sec .ms { font-size: 13px; line-height: 1.7; }
.stat { display: grid; grid-template-columns: 74px 34px 1fr; gap: 10px; align-items: center; font-size: 13px; margin: 5px 0; color: var(--s-mute); }
.stat b { text-align: right; color: var(--s-text); font-variant-numeric: tabular-nums; }
.stat .bar { height: 5px; border-radius: 999px; background: rgba(255,255,255,0.08); overflow: hidden; }
.stat .bar i { display: block; height: 100%; border-radius: 999px; background: linear-gradient(90deg, var(--s-accent-2), var(--s-accent)); }
.move { position: relative; padding: 10px 12px 10px 16px; border-radius: 12px; background: rgba(255,255,255,0.035); margin-bottom: 6px; overflow: hidden; }
.move::before { content: ""; position: absolute; left: 0; top: 0; bottom: 0; width: 4px; background: var(--c); }
.move .mt { display: flex; justify-content: space-between; align-items: center; font-weight: 700; font-size: 14.5px; }
.move .ms { font-size: 12px; color: var(--s-mute); margin-top: 3px; line-height: 1.4; }

/* Bag */
.pockets { display: flex; gap: 4px; padding: 4px; border-radius: 14px; background: rgba(0,0,0,0.25); border: 1px solid var(--s-line); }
.pockets button { flex: 1; padding: 8px 4px; border-radius: 10px; background: transparent; border: none; font-weight: 600; font-size: 12.5px; color: var(--s-mute); cursor: pointer;
  display: flex; align-items: center; justify-content: center; gap: 6px; transition: background 0.15s, color 0.15s; }
.pockets button span { font-size: 16px; }
.pockets button.on { background: rgba(255,255,255,0.1); color: var(--s-text); box-shadow: 0 2px 8px rgba(0,0,0,0.3); }
.item { display: grid; grid-template-columns: 36px 1fr auto; gap: 10px; align-items: center; padding: 10px 12px; border-radius: 14px; background: var(--s-card); border: 1px solid var(--s-line);
  cursor: pointer; text-align: left; color: inherit; font: inherit; font-weight: 600; transition: background 0.15s, border-color 0.15s; }
.item:hover { background: var(--s-card-hi); }
.item.on { border-color: rgba(245,185,66,0.55); background: rgba(245,185,66,0.08); }
.item .ic { font-size: 22px; text-align: center; }
.item .ic img { width: 36px; height: 36px; display: block; filter: drop-shadow(0 2px 3px rgba(0,0,0,0.45)); }
.item-desc .big { float: left; margin: 0 12px 4px 0; }
.item-desc .big img { width: 64px; height: 64px; display: block; filter: drop-shadow(0 4px 6px rgba(0,0,0,0.5)); }
.item-desc::after { content: ""; display: block; clear: both; }
.item .qty { font-weight: 700; font-size: 13px; color: var(--s-mute); font-variant-numeric: tabular-nums; }
.item-desc { padding: 12px 14px; border-radius: 16px; background: rgba(0,0,0,0.28); border: 1px solid var(--s-line); font-size: 13.5px; line-height: 1.5; color: var(--s-mute); }
.item-desc b { color: var(--s-text); }
.btn-main { margin-top: 10px; width: 100%; padding: 12px; border-radius: 12px; border: none; cursor: pointer; font-weight: 700; font-size: 14.5px; color: #1b1406;
  background: linear-gradient(135deg, #ffd27a, var(--s-accent) 45%, var(--s-accent-2)); box-shadow: 0 6px 18px rgba(245,160,60,0.3); }
.money { display: flex; align-items: center; justify-content: flex-end; gap: 6px; font-weight: 700; font-size: 13px; color: var(--s-accent); padding: 2px 4px; }
.money img { width: 26px; height: 26px; }

/* Journal pages */
.scr .page { padding: 16px; border-radius: 14px; background: #efe4c8; color: #3a2a18; font-family: Georgia, serif; white-space: pre-line; line-height: 1.55; box-shadow: 0 6px 16px rgba(0,0,0,0.35); }
.scr .page h3 { margin: 0 0 8px; font-size: 16px; }

/* Debug rows */
.scr .row { display: flex; gap: 12px; align-items: center; padding: 11px 12px; border-radius: 14px; background: var(--s-card); }
.scr .row .ic { font-size: 20px; width: 28px; text-align: center; }
.scr .row .t { font-weight: 700; } .scr .row .s { font-size: 12.5px; color: var(--s-mute); }

/* Main menu: a compact list anchored top-right, like Pokémon's Start menu */
.scr.mainmenu { align-items: flex-start; justify-content: flex-end; background: rgba(6,8,12,0.3); }
.scr.mainmenu .scr-win { width: min(250px, 78vw); padding: 12px; margin-top: 2px; }
.scr.mainmenu .scr-head { margin-bottom: 8px; }
.scr.mainmenu .scr-body { gap: 4px; }
.mm { display: flex; align-items: center; gap: 12px; padding: 11px 12px; border-radius: 12px; background: transparent; border: 1px solid transparent; color: inherit;
  font: 600 15.5px system-ui, -apple-system, "Segoe UI", sans-serif; cursor: pointer; text-align: left; transition: background 0.12s; }
.mm span img { width: 26px; height: 26px; }
.mm span { width: 32px; height: 32px; display: grid; place-items: center; font-size: 17px; border-radius: 10px; background: var(--s-card); border: 1px solid var(--s-line); }
.mm:hover, .mm:focus-visible { background: var(--s-card-hi); outline: none; }
.mm.home { margin-top: 4px; border-top: 1px solid var(--s-line); border-radius: 0 0 12px 12px; }

/* Action sheet (choices for one dino or item) */
.scr-sheet { position: absolute; inset: 0; pointer-events: auto; background: rgba(4,6,10,0.4); display: flex; align-items: flex-end; justify-content: center; z-index: 3;
  padding: 0 12px calc(12px + env(safe-area-inset-bottom)); animation: scr-fade 0.15s ease-out; }
.scr-sheet-box { width: min(420px, 100%); background: linear-gradient(180deg, rgba(34,38,48,0.97), rgba(20,23,30,0.97)); border: 1px solid var(--s-line); border-radius: 22px;
  padding: 14px; display: flex; flex-direction: column; gap: 6px; box-shadow: 0 20px 50px rgba(0,0,0,0.6); animation: scr-pop 0.2s cubic-bezier(0.16, 1, 0.3, 1); color: var(--s-text); }
.scr-sheet-t { font-weight: 700; font-size: 13px; color: var(--s-mute); text-align: center; margin-bottom: 4px; letter-spacing: 0.3px; }
.scr-sheet button { padding: 12px; border-radius: 14px; background: var(--s-card); border: 1px solid var(--s-line); font-weight: 600; font-size: 15px; cursor: pointer; color: inherit;
  display: flex; flex-direction: column; align-items: center; gap: 2px; transition: background 0.12s; }
.scr-sheet button:hover:not(:disabled) { background: var(--s-card-hi); }
.scr-sheet button small { font-weight: 500; font-size: 11.5px; color: var(--s-mute); }
.scr-sheet button:disabled { opacity: 0.35; cursor: default; }
.scr-sheet button.cancel { background: transparent; border-color: transparent; color: var(--s-mute); }

/* Dinodex */
.dex-count { display: flex; gap: 14px; align-items: baseline; font-size: 13px; color: var(--s-mute); padding: 0 4px; }
.dex-count b { color: var(--s-accent); font-size: 16px; margin-left: 3px; }
.dex-count .of { margin-left: auto; }
.dgrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(92px, 1fr)); gap: 8px; }
.dcard { position: relative; display: flex; flex-direction: column; align-items: center; gap: 2px; padding: 18px 4px 8px; border-radius: 14px; cursor: pointer;
  background: var(--s-card); border: 1px solid var(--s-line); color: inherit; font: inherit; transition: background 0.15s, border-color 0.15s, transform 0.1s; }
.dcard:hover, .dcard:focus-visible { background: var(--s-card-hi); border-color: rgba(255,255,255,0.2); outline: none; }
.dcard:active { transform: scale(0.97); }
.dcard.caught { background: radial-gradient(ellipse at 50% 35%, rgba(245,185,66,0.16), var(--s-card) 70%); border-color: rgba(245,185,66,0.35); }
.dnum { position: absolute; top: 5px; left: 8px; font-size: 10px; font-weight: 700; color: var(--s-mute); font-variant-numeric: tabular-nums; }
.dball { position: absolute; top: 3px; right: 5px; }
.dball img { width: 18px; height: 18px; display: block; }
.dpic { height: 54px; display: grid; place-items: center; }
.dpic img { width: 80px; height: 52px; object-fit: contain; }
.dcard img.egg { width: 46px; height: 46px; }
img.seen { filter: grayscale(1) brightness(0.75) opacity(0.55); }
img.caught { filter: drop-shadow(0 3px 4px rgba(0,0,0,0.45)); }
.dname { font-size: 11.5px; font-weight: 600; text-align: center; line-height: 1.2; min-height: 2.4em; display: flex; align-items: center; }
.dcard.unseen .dname { color: var(--s-mute); }
.dex-big { width: 120px; height: 96px; display: grid; place-items: center; }
.dex-big img { width: 120px; height: 92px; object-fit: contain; }
.dex-big img.egg { width: 84px; height: 84px; }
`;
