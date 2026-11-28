# Continuum v0.2.1 RC 1 visual acceptance

These screenshots show Rails serving the extracted candidate archive through
Brave on isolated canonical HTTPS origins. The images show the v0.2.1 footer.
Signed-in views use a disposable Auth fixture.

Candidate `1181843635418eff0fc4f06a17097fdf5527e033`
Archive SHA-256 `df0d3ac4b13423c7ae334fd91c7ec7e1ac688b8355a71236a8f648b3e51e07e8`

| View | Light | Dark |
| --- | --- | --- |
| Desktop hover · 1440 × 900 | [Light](desktop-network-light-hover.webp) | [Dark](desktop-network-dark-hover.webp) |
| Mobile closed · 390 × 844 | [Light](mobile-network-light-closed.webp) | [Dark](mobile-network-dark-closed.webp) |
| Mobile open · 390 × 844 | [Light](mobile-network-light-open.webp) | [Dark](mobile-network-dark-open.webp) |

Signed-in views show the [desktop header](desktop-signed-in.webp) and the
mobile header with the [menu closed](mobile-signed-in-closed.webp) or
[open](mobile-signed-in-open.webp).

## Visual and browser results

Across 24 anonymous host, theme and viewport combinations, Brave verified
14px type at weight 500, 8px corners, 44px targets, no horizontal overflow,
plain default links, hover and keyboard feedback, and static route-selected
current text. Desktop links remained inline. At 700px and below, touch and
keyboard opened the disclosure. Escape closed it and returned focus. Blocking
the menu script left the navigation links reachable on mobile. The signed-in
fixture passed direct visits to all three hosts. Desktop spacing from the navigation to the signed-in account trigger was
20px on the exact RC. Mobile forced-colors checks also passed.

The current item and mobile disclosure follow the owner-approved presentation.
Signed Shell v2.3.0 still describes a 600-weight current state and three links
in CT-01. Its Continuum scopes bind the prior release. This evidence supports
a forward scoped disposition and does not change the signed inputs.

Anonymous artwork-ready footer ratios were measured from the exact archive.

| Host | Viewport | Ordinary text | Jim Harvey link |
| --- | --- | ---: | ---: |
| Library | 1440 × 900 | 2.7623:1 | 4.3739:1 |
| Library | 390 × 844 | 1.8679:1 | 4.0207:1 |
| Intelligence | 1440 × 900 | 2.4675:1 | 2.3414:1 |
| Intelligence | 390 × 844 | 2.5669:1 | 2.3080:1 |

The exact link name, destination and keyboard reachability passed.
Intelligence's independent focus bands measured 17.7563:1 at both widths.
The revised ordinary text measurements require exact Infrastructure approval.

[Exact-SHA hosted CI](https://github.com/harvj/continuum/actions/runs/45322226354)
passed. The extracted archive passed 29 Rails tests with 999 assertions and
the isolated exact-archive release identity checks. The application's Auth
implementation, runtime dependencies, and database schema match v0.2.0.
[Infrastructure PR #28](https://github.com/harvj/infrastructure/pull/28)
contains the exact candidate's proposed signed disposition.

## Production acceptance

Infrastructure published Continuum-only Shell v2.4.0 with manifest SHA-256
`918752db69fcc83a7751ccc7aa0cedd7721dbb30efff75c565db050a7fe4043c`.
The exact signed preflight passed at adopted v2.3.0. Global v1.3.0 stayed
in force. [Signed publication receipt](https://github.com/harvj/infrastructure/pull/28#issuecomment-7121572562)

The deployed SHA matches the candidate and the public archive.
All three public HTTPS hosts passed desktop and mobile navigation,
touch, Escape, artwork, favicons, health and v0.2.1 footer checks.
The authentication implementation and protected production configuration
match v0.2.0. This visual-only release used the existing real White Sands
evidence and automated signed-in RC fixture checks. Neighboring process and
HTTPS baselines matched. Only the Continuum service was restarted.
[GitHub release](https://github.com/harvj/continuum/releases/tag/v0.2.1)
