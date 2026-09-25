# Hawthorn

Hawthorn is a home bar for someone who already owns the bottles and wants one cocktail from exactly three of them.

The tin is a closed fold: Bare, Tagged, or Shaken. An empty tin is Bare. Tag writes the next open Slot from Stowed inventory and folds Bare into Tagged. Shake is legal only with three Tags. It samples one bundled recipe whose PrimaryTriple equals that set, order free, folds Tagged to Shaken, and writes a ShakeMark. A miss writes a SplitMark and stays Tagged so one Slot can be peeled and retagged. Clear is legal only on Shaken and folds back to Bare. Tag on Shaken is refused. Stowed bottles stay on the bar through Tag and Shake.

That fold is the product. Surprise is the tin, not a list of recipes. A catalog dice roll that ignores owned stock is a failed verb, because tonight's drink has to come from the tagged trio.

You would pick Hawthorn when you already know the three bottles you want to use and you want one exact match, with a miss that keeps the slots peelable instead of emptying the well.

## Who it is for

A person who keeps spirits at home and decides the drink after looking at what is already on the shelf. Hawthorn does not deliver, and it does not browse a catalog you do not own.

## Architecture

The tin is an append-only log reduced to a closed fold. Views call `TinStore`. They never write the file. That suits this product because Tag, Peel, Shake, and Clear are legal only in certain phases, and a relaunch has to rebuild the same tin from the log.

## Why you would pick it

Tag three stowed bottles, then Shake. The sample is one recipe whose PrimaryTriple equals that set. A miss keeps the slots and leaves one peelable. Clear after a shaken result returns the tin to Bare. Stock is never emptied by a shake.

## How this differs in the batch

Speedwell's persisted verb is crack-then-pour from a continuous rail: every seated bottle participates. Hawthorn commits to exactly three bottles and Shake fires only on an exact set match, with a miss that stays peelable. The navigation is the tin on Surprise, with Bar, Discover, Favorites, and Settings as sheets.

## Art

Style: holographic iridescent collage. Cutouts are isolated solid subjects. App icon, splash, and card backdrop fill the canvas.

`hwt_AppIcon` — A solid mixing tin seen from above, holographic iridescent collage, subject centred and filling the canvas edge to edge, no text, no alpha, no rounded mask

`hwt_Splash` — A tall quiet collage field with a mixing tin low in the frame and an uncluttered centre band, holographic iridescent paper layers, no readable text

`hwt_Onboarding1` — A solid closed mixing tin beside two filled bottle forms, holographic iridescent collage, the product in one glance, isolated subject

`hwt_Onboarding2` — A hand seating a solid bottle into a mixing tin, mid gesture, holographic iridescent collage, isolated subject

`hwt_Onboarding3` — A solid tin holding three bottle forms and a filled coupe shape, holographic iridescent collage, isolated subject

`hwt_EmptyHome` — A solid closed mixing tin, lid on, waiting, holographic iridescent collage, fully opaque ceramic and metal forms, not glass

`hwt_EmptyList` — A solid empty tray with no bottles, holographic iridescent collage, isolated subject

`hwt_CardBackdrop` — An abstract low-contrast holographic iridescent collage field, quiet enough for type to sit on it, no objects, no text

`hwt_ControlFace` — The solid lid of a mixing tin, a single physical control face, holographic iridescent collage, isolated subject

`hwt_TwistHero` — Three solid bottle forms seated in a mixing tin, holographic iridescent collage, isolated subject, no text

`hwt_SuccessMark` — A solid filled coupe form as a confirmation emblem, holographic iridescent collage, opaque centre, isolated subject

`hwt_HeaderDecor` — A wide solid tin rim used as a horizontal ornament, holographic iridescent collage, isolated subject

`hwt_MixingTin` — One solid mixing tin, three-quarter view, holographic iridescent collage, filled metal body, isolated subject, no text

`hwt_StowedBottle` — One solid bottle form standing alone, holographic iridescent collage, opaque body, isolated subject, no label text

`hwt_HawthorneStrainer` — One solid hawthorne strainer, coil and plate as a filled object, holographic iridescent collage, isolated subject, no text

Cutouts other than the app icon, splash, and card backdrop are generated as isolated solid subjects, then converted to PNG with a real alpha channel and transparent corners.

## Build

From this directory:

```bash
xcodegen generate
xcodebuild build-for-testing -scheme Hawthorn -destination 'generic/platform=iOS Simulator' -jobs 2 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Hawthorn -destination 'generic/platform=iOS' -jobs 2 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
```

Signing stays automatic in the project. The signing flags above are command-line only. Tests use any available iOS Simulator.
