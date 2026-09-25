<!-- gf-brief source=9006edfed27d6c7a7c18bbf014d04260ec550e46547e3dcd3c47de006a66954c written=2026-09-26T01:48:58+03:00 -->
# Hawthorn

## What it is
Hawthorn is a local cocktail matcher for people who keep a small home bar. You stow bottles you own, seat three in a tin, and shake to match a cocktail from a fixed set of recipes. Everything about the bar, tags, pins, and shake history stays on this device.

## Launch and onboarding
Cold launch shows the system launch screen, then may briefly show **"Opening the tin"** while the bar loads.

On a first launch that has not finished the introduction, three full-screen pages appear. Top right: **"Skip"** (ends the introduction and opens the home tin). Bottom: **"Next"** on pages 1–2, **"Continue"** on page 3. Page indicator: **"1 of 3"**, **"2 of 3"**, **"3 of 3"**.

1. **"Tonight comes from three bottles"** — **"Hawthorn matches one cocktail to the trio you tag. The rest of the rail stays out of the shake."**
2. **"Tag, then shake"** — **"Seat three bottles you already own. Shake reads that set. A miss leaves the slots so you can peel and retag."**
3. **"The bar stays on this device"** — **"Stowed bottles are not emptied by a shake. Pin a recipe you will make again."**

After Skip or Continue, the home tin screen appears. On a later launch, onboarding is skipped unless replayed from Settings.

Around launch, the system may also show the standard notifications permission alert (**Allow** / **Don’t Allow**). That prompt is separate from onboarding.

## Screens

### Surprise (home tin)
There is no tab bar. The home screen title line is **"Seat three, then shake."** A helper line under it changes with the tin:

- Bare: **"Tag a bottle from the tray. Three tags, then shake."**
- Tagged with seats left: **"Tag *N* more. Then shake the tin."** (*N* is how many seats remain.)
- Three tagged: **"Shake this trio. A miss stays on the tin so you can peel one slot."**
- After a successful shake: **"Clear the tin when you want a fresh triple."**

If the bar has no stowed bottles: **"The bar is empty"** / **"Add a bottle, then pour."** / **"Open the bar"** (opens Bar).

If something stalled (catalog or recovered log note with an empty bar): **"Something stalled"**, the error or recovery line, and **"Open the bar"**.

When the bar has bottles:

- **Tin** panel with **"Tin"** and **"*N* of 3 tagged"**. Three seats show the bottle name and **"Tagged"**, or **"Open slot"** and **"Waiting"**.
- Tray caption **"Stowed, ready to tag"**. Chips **"Tag *Bottle name*"** seat that bottle. **"Peel"** removes the last seat (VoiceOver: **"Peel the last slot"**).
- A primary **"Tag *Bottle name*"** when another bottle can still be seated.
- **"Shake"** (shows **"Shaking"** while busy). Disabled until three bottles are tagged.
- After a miss with three still tagged: **"Split. This trio is not a recipe. Peel one slot and tag a different bottle."**
- After a hit: recipe name, method line, **"Pin this recipe"** or **"Unpin"**, and **"Clear the tin"**.
- Sheet openers (2×2): **"Bar"**, **"Discover"**, **"Favorites"**, **"Settings"**. Each opens that sheet; dismissing (Close) returns here.

Inline refusal lines can appear under the tray (see Behaviours).

### Bar
Sheet title **"Bar"**. Close control (VoiceOver **"Close"**) returns to the tin.

Empty: **"The bar is empty"** / **"Add a bottle, then pour."** / **"Back to the tin"**.

Otherwise:

- Optional recovery note at the top (e.g. **"The tin log could not be read. Hawthorn opened an empty bar."**).
- Section **"Stowed"** — names of bottles already on the bar (not tappable).
- Section **"Still in the case"** — **"Stow *Bottle name*"** for each bundled bottle not yet stowed. Stow adds it to the bar without removing it from the case list’s remaining items.
- Bundled bottle names: **"London Dry Gin"**, **"Sweet Vermouth"**, **"Campari"**, **"Bourbon"**, **"Rye Whiskey"**, **"Dry Vermouth"**, **"Orange Bitters"**, **"Lemon"**, **"Simple Syrup"**.

### Discover
Sheet title **"Discover"**. Close returns to the tin.

Catalog error: **"Something stalled"** + message + **"Close"**.

Empty catalog: **"No triples in the catalog"** / **"Hawthorn has nothing to match against the bar yet."** / **"Close"**.

Otherwise a list of recipes. Each row shows the recipe name, a match line, and the three bottle names:

- **"Full match. All 3 bottles are stowed."**
- **"Partial match. *N* of 3 stowed."**
- **"None of these bottles are on the bar."**

Recipes and methods:

- **"Negroni"** — **"Stir gin, sweet vermouth, and Campari. Strain over ice."**
- **"Manhattan"** — **"Stir rye, sweet vermouth, and orange bitters. Strain."**
- **"Martini"** — **"Stir gin, dry vermouth, and orange bitters. Strain."**
- **"Whiskey Sour"** — **"Shake bourbon, lemon, and simple syrup."**

Rows are informational; tapping does not open another screen.

### Favorites
Sheet title **"Favorites"**. Close returns to the tin.

Empty (no pins and no shakes): **"Nothing pinned yet"** / **"Shake a matching trio on Surprise, then pin the recipe you will make again."** / **"Back to the tin"**.

Otherwise:

- Section **"Pinned"** — recipe name, method (or **"Pinned from a shake."**), **"Unpin"**.
- Section **"Pours by day"** — day keys and shake counts, or **"No shakes recorded yet."**

### Settings
Sheet title **"Settings"**. Close returns to the tin.

- Section **"Bar on this device"** — **"Stowed"** and **"Shakes"** counts.
- Section **"Introduction"** — **"Replay introduction"** (shows onboarding again and closes the sheet).
- Section **"Contact"** — **"Contact Hawthorn"** (opens the support page outside the app).
- Section **"Reset"** — **"Reset all data"**. Confirmation: **"Reset the bar on this device? Stowed bottles, tags, pins, and shake history are removed."** with **"Reset all data"** and **"Cancel"**.
- If reset fails: **"Reset failed. The tin log is still on this device."** and **"Try reset again"**.

## Features
- Three-page introduction with Skip / Next / Continue
- Stow bundled bottles onto a local bar
- Tag up to three stowed bottles into a tin; Peel the last tag
- Shake a full tin to match one cocktail; miss leaves the trio seated (Split)
- Clear the tin after a shake
- Pin / Unpin a shaken recipe
- Discover how fully each recipe’s trio is covered by the bar
- Favorites: pinned recipes and pours grouped by day
- Replay introduction
- Contact Hawthorn
- Reset all data on this device
- Persist bar, tin seats, pins, and shake history across launches

## Behaviours that can look like bugs
- **"Shake"** stays disabled (quiet style) until three bottles are tagged; then it becomes the primary control. Wait for three **"Tagged"** seats.
- **"Peel"** is disabled with no seats or after a shake. After a shake, use **"Clear the tin"** first.
- Tray **"Tag …"** chips disable when the tin is full or already shaken.
- Empty home: **"The bar is empty"** until you **"Open the bar"** and **"Stow …"** at least one bottle.
- Empty Favorites until you shake a matching trio and **"Pin this recipe"**.
- A shake miss keeps the three tags and shows **"Split. This trio is not a recipe. Peel one slot and tag a different bottle."** Peel one, retag, shake again.
- Stow does not remove a bottle from the bar when you tag or shake; only Reset clears the bar.
- Refusal lines that block a step until the condition is met: **"Stow that bottle on the bar before you tag it."**, **"That bottle is already in a slot."**, **"The tin holds three. Peel a slot to tag another."**, **"Clear the shaken tin before you tag again."**, **"Shake waits for three tagged bottles."**, **"There is no slot to peel."**, **"Clear a shaken tin. Peel is for a tagged tin."**, **"Clear is ready after a shake lands."**, **"That bottle is already on the bar."**, **"Pin a recipe after a shake writes it."**, **"That recipe is not pinned."**, **"That step did not land. Try it once more."**
- Catalog failures: **"The bundled catalog is missing. Hawthorn cannot match a triple until it is restored."** or **"The bundled catalog could not be read. Your bar is unchanged."** with **"Something stalled"**.
- Corrupt bar recovery note: **"The tin log could not be read. Hawthorn opened an empty bar."** — stow again from Bar.
- **"Opening the tin"** can flash briefly on slow loads; wait for the home screen.

## Starter content and resume
Bundled catalog always includes the nine bottles and four recipes listed under Screens.

On the iOS Simulator only, a one-time seed can stow **"London Dry Gin"**, **"Sweet Vermouth"**, **"Campari"**, **"Bourbon"**, **"Lemon"**, and **"Simple Syrup"**, pre-tag gin and sweet vermouth, and skip onboarding so the next tag and shake can finish a Negroni. On a physical device there is no that seed; the bar starts empty after onboarding.

Unfinished work resumes: stowed bottles, tagged seats, a shaken result still on the tin, pins, and pours by day return on the next launch until you Clear, Unpin, or Reset.

## Permissions
- **Notifications** — asked at cold launch (system Allow / Don’t Allow dialog). No custom usage-description string in Info.plist or build settings.
- No camera, microphone, photos, or location usage strings; those permissions are not requested.

## Absent
Genuinely absent: login or accounts, in-app purchase, ads, analytics, user-generated content (no custom recipes or user uploads), account deletion flow, App Tracking Transparency prompt.

(Local **"Reset all data"** clears on-device bar data; it is not an account deletion flow.)

## Data and support
Bar, tags, pins, and shake history stay on this device (onboarding: **"The bar stays on this device"**; Settings: **"Bar on this device"**).

On-screen support control: **"Contact Hawthorn"** in Settings → Contact (opens the support page).

## Scanning and health
None. No barcode or QR scanning. Cocktail methods are drink recipes only; no health, medical, or product-health claims and no citations.

## Platform
No region lock; counts use the device locale. Light appearance only. Portrait only on iPhone and iPad. Minimum iOS 17.0.

## Category
Food & Drink
