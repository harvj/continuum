"use strict";

const primaryToggle = document.querySelector(".primary-nav-toggle");
const primaryNav = primaryToggle.closest("nav");
const mobileNav = matchMedia("(max-width: 700px)");

function closePrimaryNav() {
  if (primaryToggle.getAttribute("aria-expanded") !== "true") return;
  if (mobileNav.matches && primaryNav.contains(document.activeElement)) primaryToggle.focus();
  primaryToggle.setAttribute("aria-expanded", "false");
}

primaryToggle.addEventListener("click", () => {
  if (primaryToggle.getAttribute("aria-expanded") === "true") closePrimaryNav();
  else primaryToggle.setAttribute("aria-expanded", "true");
});

primaryNav.addEventListener("keydown", event => {
  if (event.key === "Escape") closePrimaryNav();
});

document.addEventListener("pointerdown", event => {
  if (!primaryNav.contains(event.target)) closePrimaryNav();
});

mobileNav.addEventListener("change", closePrimaryNav);
window.addEventListener("pagehide", closePrimaryNav);
primaryNav.dataset.enhanced = "";
