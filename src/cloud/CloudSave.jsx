import { useState, useSyncExternalStore } from "react";
import { subscribe, getState, signIn, signUp, signOut, syncNow, resolveConflict } from "./sync.js";
import { describeSave } from "../storage/local.js";

const STATUS = {
  idle: { icon: "☁️", label: "Non connecté" },
  syncing: { icon: "🔄", label: "Synchronisation…" },
  synced: { icon: "✅", label: "Sauvegardé en ligne" },
  offline: { icon: "📴", label: "Hors ligne — sera envoyé plus tard" },
  error: { icon: "⚠️", label: "Erreur de synchronisation" },
  conflict: { icon: "⚠️", label: "Deux sauvegardes différentes" },
};

function useCloud() {
  return useSyncExternalStore(subscribe, getState);
}

// Small indicator for the header; opens the cloud save panel.
export function CloudSaveButton() {
  const cloud = useCloud();
  const [open, setOpen] = useState(false);
  if (!cloud.enabled) return null;
  const icon = cloud.user ? STATUS[cloud.status].icon : "☁️";
  return (
    <>
      <span onClick={() => setOpen(true)} style={{ cursor: "pointer", fontSize: "12px", opacity: cloud.user ? 1 : 0.6 }}
        title="Sauvegarde en ligne">{icon}</span>
      {(open || cloud.status === "conflict") && <CloudSavePanel cloud={cloud} onClose={() => setOpen(false)} />}
    </>
  );
}

function CloudSavePanel({ cloud, onClose }) {
  const [email, setEmail] = useState(cloud.user?.email || "");
  const [password, setPassword] = useState("");
  const [mode, setMode] = useState("signin"); // signin | signup
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const run = async (fn) => {
    setBusy(true); setError(null);
    try { await fn(); } catch (e) { setError(translateError(e)); }
    setBusy(false);
  };

  const status = STATUS[cloud.status];

  return (
    <div onClick={cloud.status === "conflict" ? undefined : onClose} style={overlay}>
      <div onClick={(e) => e.stopPropagation()} style={panel}>
        <div style={{ textAlign: "center", marginBottom: "12px" }}>
          <div style={{ fontSize: "28px" }}>☁️</div>
          <div style={title}>SAUVEGARDE EN LIGNE</div>
        </div>

        {cloud.status === "conflict" && cloud.conflict ? (
          <>
            <p style={text}>
              La sauvegarde de ce téléphone et celle en ligne sont différentes. Laquelle veux-tu garder ?
              L'autre sera remplacée.
            </p>
            <button style={choice} disabled={busy} onClick={() => run(() => resolveConflict("local"))}>
              <strong>📱 Celle de ce téléphone</strong>
              <span style={sub}>{describeSave(cloud.conflict.local)}</span>
            </button>
            <button style={choice} disabled={busy} onClick={() => run(() => resolveConflict("cloud"))}>
              <strong>☁️ Celle en ligne</strong>
              <span style={sub}>{describeSave(cloud.conflict.cloud)}</span>
            </button>
          </>
        ) : cloud.user ? (
          <>
            <p style={text}>Connecté avec <strong>{cloud.user.email}</strong></p>
            <p style={{ ...text, textAlign: "center" }}>
              {status.icon} {status.label}
              {cloud.lastSyncedAt && cloud.status === "synced" && (
                <span style={sub}> · {new Date(cloud.lastSyncedAt).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}</span>
              )}
            </p>
            {cloud.error && <p style={errorText}>{cloud.error}</p>}
            <button style={primary} disabled={busy || cloud.status === "syncing"} onClick={() => run(syncNow)}>
              🔄 Synchroniser maintenant
            </button>
            <button style={secondary} disabled={busy} onClick={() => run(signOut)}>Se déconnecter</button>
          </>
        ) : (
          <>
            <p style={text}>
              {mode === "signup"
                ? "Crée un compte pour garder ta progression en ligne et la retrouver sur n'importe quel téléphone."
                : "Connecte-toi pour retrouver ta progression sauvegardée en ligne."}
            </p>
            <input style={input} type="email" inputMode="email" autoComplete="email" placeholder="adresse@email.com"
              value={email} onChange={(e) => setEmail(e.target.value.trim())} />
            <input style={input} type="password" placeholder="Mot de passe (6 caractères min.)"
              autoComplete={mode === "signup" ? "new-password" : "current-password"}
              value={password} onChange={(e) => setPassword(e.target.value)} />
            <button style={primary} disabled={busy || !email.includes("@") || password.length < 6}
              onClick={() => run(() => (mode === "signup" ? signUp : signIn)(email, password))}>
              {busy ? "Un instant…" : mode === "signup" ? "Créer le compte" : "Se connecter"}
            </button>
            <button style={secondary} disabled={busy}
              onClick={() => { setMode(mode === "signup" ? "signin" : "signup"); setError(null); }}>
              {mode === "signup" ? "J'ai déjà un compte" : "Première fois ? Créer un compte"}
            </button>
          </>
        )}

        {error && <p style={errorText}>{error}</p>}
        {cloud.status !== "conflict" && <button style={secondary} onClick={onClose}>Fermer</button>}
      </div>
    </div>
  );
}

function translateError(e) {
  const msg = e?.message || String(e);
  if (msg === "EMAIL_CONFIRMATION_REQUIRED") return "Compte créé, mais Supabase demande une confirmation par e-mail : désactive « Confirm email » dans les réglages.";
  if (/invalid login credentials/i.test(msg)) return "E-mail ou mot de passe incorrect.";
  if (/already registered/i.test(msg)) return "Ce compte existe déjà : connecte-toi plutôt.";
  if (/password/i.test(msg)) return "Mot de passe trop faible (6 caractères minimum).";
  if (/rate limit|too many/i.test(msg)) return "Trop de demandes. Réessaie dans quelques minutes.";
  if (/fetch|network/i.test(msg)) return "Pas de connexion internet.";
  return msg;
}

const overlay = {
  position: "fixed", inset: 0, zIndex: 260, background: "rgba(0,0,0,0.85)",
  display: "flex", alignItems: "center", justifyContent: "center", padding: "16px",
};
const panel = {
  width: "100%", maxWidth: "340px", background: "linear-gradient(135deg, #141810 0%, #0e120a 100%)",
  border: "2px solid #e8a020", borderRadius: "12px", padding: "16px",
  display: "flex", flexDirection: "column", gap: "8px", color: "#f0ece0",
};
const title = { fontSize: "14px", fontWeight: 900, color: "#e8a020", letterSpacing: "2px" };
const text = { fontSize: "12px", lineHeight: 1.5, margin: 0, opacity: 0.9 };
const sub = { fontSize: "10px", opacity: 0.7, fontWeight: 400 };
const errorText = { fontSize: "11px", color: "#ff8888", margin: 0 };
const input = {
  width: "100%", padding: "10px", borderRadius: "8px", border: "1px solid #3a3828",
  background: "rgba(255,248,230,0.06)", color: "#f0ece0", fontSize: "14px", outline: "none",
};
const primary = {
  padding: "12px", borderRadius: "10px", border: "none", cursor: "pointer",
  background: "linear-gradient(135deg, #e8a020 0%, #c88818 100%)", color: "#141810",
  fontWeight: 700, fontSize: "12px", letterSpacing: "1px",
};
const secondary = {
  padding: "10px", borderRadius: "10px", cursor: "pointer", background: "transparent",
  border: "1px solid #3a3828", color: "#f0ece0", fontSize: "11px",
};
const choice = {
  ...secondary, display: "flex", flexDirection: "column", gap: "4px", textAlign: "left",
  padding: "12px", fontSize: "12px", border: "1px solid #e8a020",
};
