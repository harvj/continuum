# Continuum primary navigation review

This local preview compares the deployed v0.2.0 navigation with the newer
Infrastructure presentation guidance. The baseline stylesheet served by Network
matched the v0.2.0 Git blob. Rails renders the updated markup. Brave captures use
the published Network light and dark Site Art assets. Signed-in images use a
disposable Auth fixture.

| View | Deployed v0.2.0 | Updated light | Updated dark | Updated signed in |
| --- | --- | --- | --- | --- |
| Desktop · 1440 × 900 | [Before](desktop-before.webp) | [Hover](desktop-light.webp) | [Hover](desktop-dark.webp) | [Dark](desktop-signed-in.webp) |
| Mobile · 390 × 844 | [Before](mobile-before.webp) | [Keyboard focus](mobile-light.webp) | [Keyboard focus](mobile-dark.webp) | [Light](mobile-signed-in.webp) |

## Discrepancies and corrections

| Item | Deployed v0.2.0 | Review styling |
| --- | --- | --- |
| Default | Plain and unadorned over the current art. With plain Site Art metadata, a generic header rule could add individual rectangular backings and padding. | Links remain plain and unadorned in all palettes. The generic rectangular rule stays on the other header elements. |
| Hover and press | The link gained an underline. There was no translucent pill. | A translucent pill appears without an underline. The hit area stays fixed. |
| Keyboard focus | The generic outline showed focus. It had no translucent backing and could overlap the pointer underline. | The visible outline is paired with the translucent pill. Forced colors use the system highlight. |
| Current destination | A clickable self-link used bold, underlined text. It took a tab stop and had no solid, palette-inverted treatment. | The route-selected section is static text with `aria-current="page"`. The pill uses the effective header foreground with text in the theme surface color. |
| Geometry and type | Anchors used minimum dimensions but had no common inline inset or radius. The signed-in desktop gap to the account trigger was 16px. | All three items share an inset, Muzeum's 8px corner radius, weight and 44px minimum height. The signed-in desktop gap is 20px. On mobile the three-bar control sits in the header beside the account disclosure, when signed in. |
| Network art contrast | Bright detail in the dark illustration could reduce contrast behind plain labels. A foreground-colored translucent tint also reduced contrast in both Network themes during testing. | Network feedback is tinted toward the theme surface. A narrow dark glyph edge separates plain dark-theme labels from bright detail. |

Tested Network in light and dark, Library, and Intelligence at 1440, 701,
700, 390 and 320 CSS px. Browser checks covered semantics, targets, hover,
keyboard focus, current-pill contrast, forced colors and horizontal overflow.
At 700px and below, touch opens the menu, keyboard navigation reaches its links, and Escape closes it and restores focus. The links remain available if the menu script cannot load.
The signed-in desktop and mobile checks used the local Rails app and a
disposable Auth provider. At 1440 and 390 px, the lowest sampled hover
contrast was 5.90:1. Network dark artwork can still reach 3.85:1 within
the raw default label rectangle outside the protective glyph edge. Those
raw artwork samples do not measure contrast at the glyph boundary.

## Signed preflight and review boundary

Infrastructure merged the [new navigation guidance](https://github.com/harvj/infrastructure/pull/26)
as application adoption documentation. The signed Shell bundle and
conformance fixtures were left unchanged. Signed v2.3.0 covers geometry,
current-state semantics, control access and readability. The preflight
checks verified bundle identities and accepts candidate-bound results
from the release review. It does not render pages or compare computed
visual states. The earlier exact-candidate review therefore did not
exercise the new pill treatments or the static current item.

The preview follows the newer guidance on consistent typography.
Signed v2.3.0 still specifies a 600 weight for the current item and CT-01
describes three public section links. The preview uses weight 500 for all
items and renders the selected section as text. Reconcile those assertions
and the exact-artifact CT-01 and CT-02 bindings before deploying a new
candidate. The signed fixtures, authentication, Site Art files, footer
presentation and serving release were unchanged by this review.
