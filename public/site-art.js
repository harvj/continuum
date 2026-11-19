"use strict";

const image = document.querySelector("img[data-art-presentation]");

if (image) {
  image.decode().then(() => {
    const presentation = JSON.parse(image.dataset.artPresentation);
    for (const scope of document.querySelectorAll("[data-art-role]")) {
      const treatment = presentation[scope.dataset.artRole];
      for (const property of ["--art-foreground", "--art-text-shadow", "--art-backing"]) {
        scope.style.setProperty(property, treatment[property] ?? "initial");
      }
    }
    if (image.dataset.artLegacy) document.body.dataset.foreground = image.dataset.artLegacy;
    document.body.dataset.artReady = "";
  }, () => image.remove());
}
