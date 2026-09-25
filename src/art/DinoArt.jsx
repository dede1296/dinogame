import { DINOS } from "../data/dinos.js";
import { makePalette, Sprite, HEAD_SPRITES, HEAD_NECK_OFFSET, BODY_SPRITE, LEG_SPRITES, renderDorsal, renderTail, renderTeeth } from "./sprites.jsx";

export function DinoArt({ build, animating = true, crying = false, pattern = "none" }) {
  const headD = DINOS[build.head];
  const teethD = DINOS[build.teeth];
  const frontD = DINOS[build.frontLegs];
  const backLegsD = DINOS[build.backLegs];
  const backDorsalD = DINOS[build.back];
  const tailD = DINOS[build.tail];
  const color = build.customColor || DINOS[build.color].color;
  const palette = makePalette(color);

  const bipedFams = ["tyrant", "spino", "raptor", "hadrosaur"];
  const quadFams = ["sauropod", "ceratopsian", "armored"];
  const posture = bipedFams.includes(backLegsD.family) ? "biped"
    : quadFams.includes(backLegsD.family) ? "quad"
    : backLegsD.family === "flyer" ? "flyer"
    : "marine";

  // Body anchor
  const bodyX = 18;
  const bodyY = 20;
  const bodyW = 28;
  const bodyH = 14;

  // Head placement (end of neck, upper right)
  const headSprite = HEAD_SPRITES[headD.family] || HEAD_SPRITES.tyrant;
  const headOff = HEAD_NECK_OFFSET[headD.family] || { x: 1, y: 5 };
  const neckLen = headD.family === "sauropod" ? 16 : headD.family === "flyer" ? 6 : 7;
  const neckAngle = headD.family === "sauropod" && posture === "quad" ? -1.1 : -0.55;
  const neckStartX = bodyX + bodyW - 4;
  const neckStartY = bodyY + 2;
  const neckEndX = Math.floor(neckStartX + Math.cos(neckAngle) * neckLen);
  const neckEndY = Math.floor(neckStartY + Math.sin(neckAngle) * neckLen);
  const headX = neckEndX - headOff.x;
  const headY = neckEndY - headOff.y;

  // Neck pixels (line)
  const neckPixels = [];
  const steps = Math.max(Math.abs(neckEndX - neckStartX), Math.abs(neckEndY - neckStartY));
  for (let s = 0; s <= steps; s++) {
    const t = s / Math.max(1, steps);
    const nx = Math.round(neckStartX + (neckEndX - neckStartX) * t);
    const ny = Math.round(neckStartY + (neckEndY - neckStartY) * t);
    const nthick = headD.family === "sauropod" ? 2 : headD.family === "flyer" ? 2 : 3;
    for (let dy = 0; dy < nthick; dy++) {
      const isEdge = dy === 0 || dy === nthick - 1;
      neckPixels.push(
        <rect key={`neck-${s}-${dy}`} x={nx} y={ny + dy} width={1.02} height={1.02}
          fill={isEdge ? palette.o : palette.b} rx={0.2} />
      );
    }
  }

  // Leg selection
  let backLegSprite, frontLegSprite;
  if (posture === "biped") {
    frontLegSprite = frontD.family === "tyrant" ? LEG_SPRITES.armTiny
      : (frontD.family === "raptor" || frontD.family === "spino") ? LEG_SPRITES.armClawed
      : LEG_SPRITES.armMedium;
    backLegSprite = backLegsD.family === "raptor" ? LEG_SPRITES.bipedFast
      : backLegsD.family === "hadrosaur" ? LEG_SPRITES.bipedHadro
      : LEG_SPRITES.bipedBig;
  } else if (posture === "quad") {
    frontLegSprite = LEG_SPRITES.quadColumn;
    backLegSprite = LEG_SPRITES.quadColumn;
  } else if (posture === "flyer") {
    frontLegSprite = LEG_SPRITES.wing;
    backLegSprite = LEG_SPRITES.armMedium;
  } else {
    frontLegSprite = LEG_SPRITES.flipper;
    backLegSprite = LEG_SPRITES.flipper;
  }

  const idleAnims = ["breathe", "idle-look", "idle-bounce"];
  const idleIdx = (build.head + build.teeth + build.tail) % idleAnims.length;
  const breathe = animating ? idleAnims[idleIdx] : "";

  return (
    <svg viewBox="0 0 80 54" className="w-full h-full" shapeRendering="geometricPrecision"
      style={{ imageRendering: "auto", filter: `drop-shadow(0 6px 0 rgba(25,40,28,0.25)) drop-shadow(0 1px 3px rgba(0,0,0,0.35))${Object.values(build).some(idx => DINOS[idx]?.exclusive) ? " drop-shadow(0 0 8px rgba(196,168,56,0.6))" : ""}` }}>
      <defs>
        <pattern id="pat-stripes" patternUnits="userSpaceOnUse" width="3" height="3" patternTransform="rotate(45)">
          <rect width="1.5" height="3" fill="rgba(0,0,0,0.25)" />
        </pattern>
        <pattern id="pat-spots" patternUnits="userSpaceOnUse" width="5" height="5">
          <circle cx="2.5" cy="2.5" r="1.3" fill="rgba(0,0,0,0.22)" />
        </pattern>
        <pattern id="pat-camo" patternUnits="userSpaceOnUse" width="8" height="6">
          <ellipse cx="2" cy="2" rx="2.5" ry="1.5" fill="rgba(0,0,0,0.15)" />
          <ellipse cx="6" cy="4" rx="2" ry="1.8" fill="rgba(0,0,0,0.2)" />
        </pattern>
        {/* Smooth filter: slight blur to soften pixel edges */}
        <filter id="smooth" x="-5%" y="-5%" width="110%" height="110%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="0.15" />
        </filter>
        {/* Glow filter for rare/high friendship dinos */}
        <filter id="glowGold" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="1.2" result="blur" />
          <feFlood floodColor="#e8a020" floodOpacity="0.5" />
          <feComposite in2="blur" operator="in" />
          <feMerge>
            <feMergeNode />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        <filter id="glowPurple" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="1.2" result="blur" />
          <feFlood floodColor="#9050d0" floodOpacity="0.5" />
          <feComposite in2="blur" operator="in" />
          <feMerge>
            <feMergeNode />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        {/* Body highlight gradient */}
        <linearGradient id="bodyShine" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="rgba(255,248,230,0.1)" />
          <stop offset="50%" stopColor="rgba(255,255,255,0)" />
          <stop offset="100%" stopColor="rgba(0,0,0,0.08)" />
        </linearGradient>
      </defs>
      <style>{`
        @keyframes breathing {
          0%, 100% { transform: translateY(0) scale(1); }
          50% { transform: translateY(0.3px) scale(1.01); }
        }
        @keyframes tailSwish {
          0%, 100% { transform: rotate(0deg); }
          50% { transform: rotate(2deg); }
        }
        @keyframes cryShake {
          0%, 100% { transform: translateY(0) rotate(0); }
          20% { transform: translateY(-1px) rotate(-3deg); }
          60% { transform: translateY(-0.5px) rotate(-2deg); }
        }
        @keyframes idleLook {
          0%, 70%, 100% { transform: translateY(0) rotate(0); }
          75% { transform: translateY(-0.3px) rotate(1.5deg); }
          85% { transform: translateY(-0.3px) rotate(1.5deg); }
          90% { transform: translateY(0) rotate(0); }
        }
        @keyframes idleBounce {
          0%, 85%, 100% { transform: translateY(0) scale(1); }
          88% { transform: translateY(-1.5px) scale(1.02); }
          92% { transform: translateY(0.3px) scale(0.99); }
        }
        @keyframes dinoWalk {
          0%, 100% { transform: translateX(0) translateY(0); }
          25% { transform: translateX(2px) translateY(-0.5px); }
          50% { transform: translateX(0) translateY(0); }
          75% { transform: translateX(-2px) translateY(-0.5px); }
        }
        @keyframes footprintFade {
          0% { opacity: 0.3; }
          100% { opacity: 0; }
        }
        @keyframes victoryDance {
          0%, 100% { transform: translateY(0) rotate(0) scale(1); }
          15% { transform: translateY(-8px) rotate(-5deg) scale(1.1); }
          30% { transform: translateY(0) rotate(3deg) scale(1.05); }
          45% { transform: translateY(-6px) rotate(-3deg) scale(1.08); }
          60% { transform: translateY(0) rotate(2deg) scale(1); }
          75% { transform: translateY(-3px) rotate(-1deg) scale(1.03); }
        }
        .breathe { animation: breathing 2.4s ease-in-out infinite; transform-origin: center; }
        .idle-look { animation: idleLook 5s ease-in-out infinite; transform-origin: 60% 50%; }
        .idle-bounce { animation: idleBounce 4s ease-in-out infinite; transform-origin: center bottom; }
        .cry-shake { animation: cryShake 0.6s ease-out; transform-origin: 70% 60%; }
      `}</style>

      {/* Ground shadow */}
      <ellipse cx={40} cy={52} rx={20} ry={3} fill="rgba(0,0,0,0.12)">
        <animate attributeName="rx" values="19;21;19" dur="2.4s" repeatCount="indefinite" />
      </ellipse>

      <g className={crying ? "cry-shake" : breathe}>
        {/* Aura for rare/high friendship dinos */}
        {(() => {
          const hasLeg = Object.values(build).some(idx => DINOS[idx]?.rarity === "legendary");
          const hasEpic = Object.values(build).some(idx => DINOS[idx]?.rarity === "epic");
          if (hasLeg) return <ellipse cx={40} cy={30} rx={22} ry={18} fill="none" stroke="#e8a020" strokeWidth={0.4} opacity={0.4} filter="url(#glowGold)"><animate attributeName="rx" values="20;24;20" dur="2.5s" repeatCount="indefinite" /><animate attributeName="opacity" values="0.3;0.6;0.3" dur="2.5s" repeatCount="indefinite" /></ellipse>;
          if (hasEpic) return <ellipse cx={40} cy={30} rx={20} ry={16} fill="none" stroke="#9050d0" strokeWidth={0.3} opacity={0.3} filter="url(#glowPurple)"><animate attributeName="rx" values="18;22;18" dur="3s" repeatCount="indefinite" /><animate attributeName="opacity" values="0.2;0.5;0.2" dur="3s" repeatCount="indefinite" /></ellipse>;
          return null;
        })()}
        {/* Tail - rendered first so body overlaps */}
        {renderTail(tailD.family, tailD.tail.power, tailD.tail.length,
          bodyX + 2, bodyY + 8, palette, backDorsalD.back.spikes)}

        {/* Back legs */}
        {posture === "quad" ? (
          <>
            <Sprite data={backLegSprite} x={bodyX + 20} y={bodyY + bodyH - 2} palette={palette} />
          </>
        ) : posture === "biped" ? (
          <Sprite data={backLegSprite} x={bodyX + 15} y={bodyY + bodyH - 2} palette={palette} />
        ) : posture === "flyer" ? (
          <Sprite data={backLegSprite} x={bodyX + 16} y={bodyY + bodyH - 1} palette={palette} />
        ) : (
          <Sprite data={backLegSprite} x={bodyX + 20} y={bodyY + bodyH - 2} palette={palette} />
        )}

        {/* Body */}
        <Sprite data={BODY_SPRITE} x={bodyX} y={bodyY} palette={palette} />
        {/* Pattern overlay on body */}
        {pattern && pattern !== "none" && (
          <rect x={bodyX + 3} y={bodyY + 2} width={bodyW - 6} height={bodyH - 4} rx={2}
            fill={`url(#pat-${pattern})`} />
        )}
        {/* Body shine highlight */}
        <rect x={bodyX + 3} y={bodyY + 1} width={bodyW - 6} height={bodyH - 2} rx={2}
          fill="url(#bodyShine)" opacity={0.6} />

        {/* Dorsal feature */}
        {renderDorsal(backDorsalD.family, backDorsalD.back.spikes, backDorsalD.back.armor,
          bodyX + 4, bodyY + 1, bodyW - 8, palette)}

        {/* Front legs/arms */}
        {posture === "quad" ? (
          <Sprite data={frontLegSprite} x={bodyX + 4} y={bodyY + bodyH - 2} palette={palette} />
        ) : posture === "biped" ? (
          <Sprite data={frontLegSprite} x={bodyX + 18} y={bodyY + 7} palette={palette} />
        ) : posture === "flyer" ? (
          <Sprite data={frontLegSprite} x={bodyX - 4} y={bodyY + 2} palette={palette} />
        ) : (
          <Sprite data={frontLegSprite} x={bodyX + 3} y={bodyY + bodyH - 3} palette={palette} />
        )}

        {/* Neck */}
        {neckPixels}

        {/* Head */}
        <Sprite data={headSprite} x={headX} y={headY} palette={palette} />

        {/* Teeth inside head mouth area */}
        {renderTeeth(headD.family, teethD.teeth.count, teethD.teeth.sharp,
          headX + headOff.x + 2, headY + headSprite.length - 3,
          headSprite[0].length - headOff.x - 4, palette)}
      </g>
    </svg>
  );
}
