# v0.1.2 Site Art presentation

Continuum applies the optional Site Art v1 foreground and glyph shadow by
role. The header and navigation use the top region, the footer uses the
bottom region, and main content uses flat treatment. The footer can also
show an explicit backing. The neutral host theme remains visible until
the background decodes and stays in use if decoding fails.

Metadata-only releases keep the image's immutable URL and update the
treatment on the next navigation. Continuum preserves the read-only
snapshot integration and its 30-second refresh window. The release needs
no database migration.

The [Intelligence preview](design/intelligence-preview.html) uses the current
artwork from the sibling Site Art checkout. Samples of the current footer
contrast reach about 2.3:1 at desktop and mobile sizes, below the 4.5:1
target for normal text.
