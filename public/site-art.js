"use strict";

let displayed = document.querySelector("img.background");
let selection = 0;

function install(image) {
  const presentation = JSON.parse(image.dataset.artPresentation);
  for (const scope of document.querySelectorAll("[data-art-role]")) {
    const treatment = presentation[scope.dataset.artRole];
    for (const property of ["--art-foreground", "--art-text-shadow", "--art-backing"]) {
      scope.style.setProperty(property, treatment[property] ?? "initial");
    }
  }
  const { body } = document;
  delete body.dataset.foreground;
  body.toggleAttribute("data-art-plain", !image.dataset.artLegacy &&
    Object.values(presentation).every(treatment => Object.keys(treatment).length === 0));
  if (image.dataset.artLegacy) body.dataset.foreground = image.dataset.artLegacy;
  if (image !== displayed) {
    displayed?.remove();
    body.prepend(image);
    displayed = image;
  }
  body.dataset.artReady = "";
}

async function selectArt(image) {
  const request = ++selection;
  if (image === displayed && document.body.hasAttribute("data-art-ready")) {
    install(image);
    return true;
  }
  try {
    await image.decode();
  } catch {
    if (request === selection && !document.body.hasAttribute("data-art-ready")) {
      displayed?.remove();
      displayed = null;
    }
    return false;
  }
  if (request === selection) install(image);
  return true;
}

const appearance = document.querySelector(".appearance");
if (appearance) {
  const templates = Object.fromEntries([...document.querySelectorAll("template[data-art-mode]")]
    .map(template => [template.dataset.artMode, template]));
  const system = matchMedia("(prefers-color-scheme: dark)");
  const storageKey = "continuum-appearance";
  const trigger = appearance.querySelector("summary");
  let preference = "system";
  const images = new Map();

  try {
    const stored = localStorage.getItem(storageKey);
    if (Object.hasOwn(templates, stored)) preference = stored;
  } catch {
    // The current page still supports appearance when storage is unavailable.
  }

  function applyPreference() {
    const mode = preference === "system" ? (system.matches ? "dark" : "light") : preference;
    if (!images.has(mode)) {
      images.set(mode, document.importNode(templates[mode].content.querySelector("img"), false));
    }
    const image = images.get(mode);
    selectArt(image).then(decoded => {
      if (!decoded && images.get(mode) === image) images.delete(mode);
    });
  }

  function closeAppearance() {
    if (!appearance.open) return;
    if (appearance.contains(document.activeElement)) trigger.focus();
    appearance.open = false;
  }

  appearance.querySelector(`input[value="${preference}"]`).checked = true;
  appearance.addEventListener("change", event => {
    preference = event.target.value;
    try {
      if (preference === "system") localStorage.removeItem(storageKey);
      else localStorage.setItem(storageKey, preference);
    } catch {
      // Keep the selection for the current page.
    }
    applyPreference();
  });
  appearance.addEventListener("keydown", event => {
    if (event.key === "Escape" && appearance.open) {
      event.preventDefault();
      closeAppearance();
    }
  });
  document.addEventListener("pointerdown", event => {
    if (!appearance.contains(event.target)) closeAppearance();
  });
  system.addEventListener("change", () => {
    if (preference === "system") applyPreference();
  });
  appearance.hidden = false;
  applyPreference();
} else if (displayed) {
  selectArt(displayed);
}
