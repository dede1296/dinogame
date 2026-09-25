import { JP_NOTES } from "../data/musicTheme.js";

let musicCtx = null;
let musicNodes = [];
let musicPlaying = false;
let musicTimer = null;

export function startMusic(mood) {
  stopMusic();
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return;
  try {
    musicCtx = new AC();
    if (musicCtx.state === "suspended") musicCtx.resume();
    const master = musicCtx.createGain();
    master.gain.value = 0.18;
    master.connect(musicCtx.destination);
    musicPlaying = true;

    if (mood === "battle") {
      // Tense battle: pulsing Dm chord
      const now = musicCtx.currentTime;
      [73.4, 87.3, 110, 146.8].forEach((freq, i) => {
        const osc = musicCtx.createOscillator();
        const gain = musicCtx.createGain();
        osc.type = i < 2 ? "sawtooth" : "triangle";
        osc.frequency.value = freq;
        gain.gain.value = 0.15;
        const filt = musicCtx.createBiquadFilter();
        filt.type = "lowpass"; filt.frequency.value = 300 + i * 80;
        osc.connect(filt).connect(gain).connect(master);
        osc.start(now); musicNodes.push(osc);
        const pulse = () => {
          if (!musicPlaying) return;
          gain.gain.setValueAtTime(0.25, musicCtx.currentTime);
          gain.gain.setTargetAtTime(0.05, musicCtx.currentTime + 0.2, 0.5);
          setTimeout(pulse, 1800 + i * 200);
        };
        setTimeout(pulse, 1000);
      });
    } else {
      // MIDI theme playback — robust scheduler
      const LOOK_AHEAD = 4.0; // schedule 4 seconds ahead
      const SCHEDULE_INTERVAL = 1500; // check every 1.5s
      let cursor = 0; // current note index
      let startTime = musicCtx.currentTime;

      const scheduleAhead = () => {
        if (!musicPlaying || !musicCtx) return;
        const now = musicCtx.currentTime;
        const horizon = now + LOOK_AHEAD;

        while (cursor < JP_NOTES.length) {
          const [t, freq, dur, vel] = JP_NOTES[cursor];
          const when = startTime + t;
          if (when > horizon) break; // too far ahead, wait
          if (when >= now - 0.05) { // skip notes in the past
            const osc = musicCtx.createOscillator();
            const gain = musicCtx.createGain();
            osc.type = freq > 400 ? "triangle" : "sine";
            osc.frequency.value = freq;
            const filt = musicCtx.createBiquadFilter();
            filt.type = "lowpass";
            filt.frequency.value = Math.min(2000, freq * 3);
            filt.Q.value = 0.5;
            const attackT = Math.min(0.08, dur * 0.15);
            const releaseT = Math.min(0.3, dur * 0.3);
            gain.gain.setValueAtTime(0, when);
            gain.gain.linearRampToValueAtTime(vel * 0.4, when + attackT);
            gain.gain.setTargetAtTime(vel * 0.25, when + attackT, dur * 0.3);
            gain.gain.setTargetAtTime(0.001, when + dur - releaseT, releaseT * 0.5);
            osc.connect(filt).connect(gain).connect(master);
            osc.start(when);
            osc.stop(when + dur + 0.1);
          }
          cursor++;
        }

        // Loop if we've reached the end
        if (cursor >= JP_NOTES.length) {
          const totalDur = JP_NOTES[JP_NOTES.length - 1][0] + JP_NOTES[JP_NOTES.length - 1][2] + 1.5;
          startTime = startTime + totalDur;
          cursor = 0;
        }

        musicTimer = setTimeout(scheduleAhead, SCHEDULE_INTERVAL);
      };
      scheduleAhead();
    }
  } catch(e) {}
}

export function stopMusic() {
  musicPlaying = false;
  if (musicTimer) { clearTimeout(musicTimer); musicTimer = null; }
  musicNodes.forEach(n => { try { n.stop(); } catch(e) {} });
  musicNodes = [];
  if (musicCtx) { try { musicCtx.close(); } catch(e) {} musicCtx = null; }
}
