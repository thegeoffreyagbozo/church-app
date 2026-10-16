# ADR 0010: Each platform's own tab bar

**Status:** Accepted · **Date:** 2026-10-16 · **Amends:** [ADR 0009](./0009-reading-experience.md)

## Context
ADR 0009 drew the Home tab bar as a floating glass pill on every platform. On a bright Android
screen in Paper it barely read as a bar (the page colour laid over the page colour, a white
border on near-white), and it was not the Android control members already know from their other
apps. Its blur also costs work on low-end phones on every scroll of a tab. iOS 26 brought Liquid
Glass, Apple's own floating glass tab bar, which Flutter does not draw.

## Decision
- **Android:** the standard Material 3 navigation bar, docked full width at the bottom: a solid
  surface with a hairline top edge, the selected tab in the brand colour on a tinted pill, labels
  always shown. Lists on the tabs end above it.
- **iPhone:** the iOS tab bar (`CupertinoTabBar`) in the same colours. It stays as the fallback
  for iOS before 26.
- **Liquid Glass on iOS 26 waits for the iOS build.** The native bar needs a package that hosts
  UIKit's `UITabBar` in a platform view. Checked on 2026-10-16:
  - `cupertino_native` 0.1.1 calls itself a proof of concept and was last published in 2025; its
    README lists combining native views with scroll views as open work.
  - `cupertino_native_better` 1.6.0 builds on it, with release-safe iOS version detection and a
    Material fallback on other platforms.
  - `adaptive_platform_ui` 1.0.2 shows Material on Android, Cupertino before iOS 26 and the
    native `UITabBar` on iOS 26 and later, but is built around its own scaffold.

  Platform views can't be built or tested without a Mac, so the choice is made with the first
  iOS build, on an iOS 26 iPhone, behind the same platform switch in `HomeShell`.

## Consequences
- The tab bar looks and behaves the way each platform's users expect, and stays legible on
  bright screens.
- Glass remains on the pinned header of hymn and reading pages, the `···` menu and sheets
  (ADR 0009).
- One more dependency arrives with the iOS build, once it has been tried on a device.
