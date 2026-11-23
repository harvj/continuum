"use strict";

const disclosure = document.querySelector(".shell-session");
const opener = disclosure.querySelector("summary");
const group = disclosure.querySelector(".shell-applications");
const destinations = group.querySelector("ul");
const context = disclosure.dataset.context;
const sessions = typeof BroadcastChannel === "function" ? new BroadcastChannel("continuum-session") : null;
let pending;
let expiry;
let suspended = false;

function clearDestinations() {
  pending?.abort();
  pending = null;
  clearTimeout(expiry);
  group.hidden = true;
  destinations.replaceChildren();
}

async function refreshDestinations() {
  clearDestinations();
  if (!disclosure.open || suspended || document.hidden) return;
  const request = new AbortController();
  pending = request;
  const started = performance.now();
  expiry = setTimeout(() => request.abort(), 12000);

  try {
    const response = await fetch("/shell/destinations", {
      cache: "no-store",
      headers: { "X-Continuum-Shell": context },
      signal: request.signal
    });
    if (request !== pending || !disclosure.open) return;
    if (response.status === 401) {
      window.location.reload();
      return;
    }
    if (response.status !== 200) return;
    const result = await response.json();
    if (request !== pending || request.signal.aborted || !disclosure.open) return;
    const remaining = Math.min(result.ttl_ms, 60000) - (performance.now() - started);
    if (!(remaining > 0)) return;

    disclosure.querySelector(".shell-session-name").textContent = result.username;
    for (const destination of result.destinations) {
      const item = document.createElement("li");
      const link = document.createElement("a");
      link.textContent = destination.name;
      link.href = destination.canonical_url;
      item.append(link);
      destinations.append(item);
    }
    group.hidden = destinations.childElementCount === 0;
    clearTimeout(expiry);
    expiry = setTimeout(() => {
      if (destinations.contains(document.activeElement)) opener.focus();
      refreshDestinations();
    }, remaining);
  } catch {
    // Keep the local identity and clear links when evidence is unavailable.
  }
}

function closeDisclosure() {
  if (!disclosure.open) return;
  if (disclosure.contains(document.activeElement)) opener.focus();
  disclosure.open = false;
  clearDestinations();
}

disclosure.addEventListener("toggle", refreshDestinations);
disclosure.addEventListener("keydown", event => {
  if (event.key === "Escape" && disclosure.open) {
    event.preventDefault();
    closeDisclosure();
  }
});
document.addEventListener("pointerdown", event => {
  if (!disclosure.contains(event.target)) closeDisclosure();
});
document.addEventListener("visibilitychange", () => {
  if (document.hidden) closeDisclosure();
});
window.addEventListener("pagehide", () => {
  suspended = true;
  closeDisclosure();
});
window.addEventListener("pageshow", event => {
  if (event.persisted) window.location.reload();
});

sessions?.addEventListener("message", event => {
  if (event.data !== context) {
    closeDisclosure();
    window.location.reload();
  }
});
sessions?.postMessage(context);
