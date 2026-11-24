"use strict";

const form = document.querySelector("form");
if (form) {
  form.requestSubmit();
} else {
  window.location.replace(document.querySelector("a").href);
}
