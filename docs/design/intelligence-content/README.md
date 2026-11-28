# Intelligence managed content preview

[Desktop at 1440 × 900](desktop.webp) · [Mobile at 390 × 844](mobile.webp)

Brave captured the Rails view with the approved Intelligence Site Art and
the Auth handoff's example supplied only as a disposable test fixture.
The quote is centered directly on the yellow sky. Background samples across
the article area measured at least 12.74:1 against the quote ink, so no
backing was added. The italic quote and separate attribution fit without
horizontal scrolling at 320px.

Continuum reads `continuum.intelligence` through the protected Intelligence
registration. A successful empty response updates the display title and
removes the optional region. The first request starts the background reader
without waiting. Conditional refreshes run about every minute. A transient
failure may retain a verified response for five minutes, while denied or
missing content clears it. The producer and consumer tests cover publication,
edits, rename and withdrawal without a process restart.

The live protected API returned 200 with an ETag and no published main region.
The same validator returned 304 with an empty body. Network credentials were
denied with 404. The visual and lifecycle fixtures made no live editorial changes.

## Production outcome

Continuum v0.3.0 is live at `c9d6e87d7537cadf80bd147242ede5e001d97fe0`.
The production worker emitted its verified-representation event after a
public Intelligence request. The live region is empty and the page renders
without an article. No live editorial changes were made. Auth publisher
coverage passed 17 disposable examples, and exact extracted Continuum passed
34 tests and 1,050 assertions. Hosted CI, reusable signed Shell v2.5.0
preflight and independent production checks passed.
[Hosted CI](https://github.com/harvj/continuum/actions/runs/45742461924) ·
[GitHub release](https://github.com/harvj/continuum/releases/tag/v0.3.0)
