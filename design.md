# Attendify — Design System & UI/UX Specification

## 1. Design Direction

Attendify should look like a calm, premium student productivity product rather than a university ERP.

The design goal is:

> **Minimal enough to feel premium, rich enough to feel complete.**

The visual system combines:

- warm light-theme surfaces
- muted terracotta/rose accents
- soft sage success states
- restrained amber/coral warnings
- subtle nature/landscape artwork
- refined editorial headings
- clean functional typography
- controlled liquid-glass / glassmorphic materials
- fast, subtle motion

Dark theme is deliberately deferred. The architecture must make it possible later without rewriting screens.

## 2. Light Theme Palette

| Token | Suggested value | Use |
|---|---|---|
| Background | `#F7F1EC` | Main page background |
| Surface | `#FFFDFC` | Primary content surface |
| Glass | `rgba(255,255,255,0.58)` | Translucent surfaces |
| Terracotta | `#C96E5B` | Primary accent / actions |
| Rose | `#D98786` | Warm secondary accent |
| Sage | `#72A68A` | Safe / attended / positive |
| Amber | `#D9A35B` | Warning / attention |
| Coral | `#D86A62` | Critical / absent |
| Lavender | `#8F7BAE` | Academic/secondary events |
| Ink | `#202020` | Main text |
| Muted Ink | `#6E6A67` | Secondary text |
| Divider | `rgba(48,38,34,0.08)` | Soft separators |

Do not use all accents at the same time on one card. Colours are semantic rather than decorative.

## 3. Semantic Colour Rules

**Terracotta/Rose:** primary actions, selected navigation, important focus states, brand identity.

**Sage:** attended, safe, target reached, positive trend.

**Amber:** approaching minimum, needs attention.

**Coral:** below minimum, absent, critical.

**Lavender:** academic events, assessments and secondary categories.

**Grey:** neutral, not-held and disabled states.

Never communicate a status through colour alone. Pair colour with text and/or an icon.

## 4. Nature / Landscape Language

The application should consistently use subtle illustrations of:

- mountains
- trees
- small sun
- leaves/branches
- occasional birds/clouds

These should sit behind headers/edges rather than behind dense content. Colours should be softened versions of the core palette.

Dashboard can have the richest landscape header. Analytics should use the lightest illustration because it is the densest screen.

Do not repeat the same illustration at full strength on every screen.

## 5. Liquid Glass

Use a premium Apple-like material feel as inspiration, but maintain an independent Attendify identity.

The glass effect is **restrained**.

Conceptual recipe:

- translucent warm-white surface
- 12–24px backdrop blur
- 1px low-opacity border
- broad soft shadow
- subtle tint from the background
- generous radius

Use glass mainly for:

- floating bottom navigation
- top controls
- major summary cards
- dropdowns
- bottom sheets
- contextual overlays
- selected controls

Avoid applying glass blindly to every list row. Dense content should remain readable on stronger surfaces.

> **Liquid-glass touch, not liquid-glass everywhere.**

## 6. Cards

Cards should belong to one coherent family.

Suggested radius scale:

- small control: 12–14
- standard card: 18
- feature card: 22–24
- bottom sheet: 28–32

Use consistent internal padding and header spacing.

Do not put a large feature card beside many tiny cards without a clear information hierarchy.

## 7. Typography

Use an elegant serif/editorial typeface sparingly for large page headings and a highly legible sans-serif for functional text.

Hierarchy:

**Page title → section title → card title → primary metric → supporting value → metadata**

Attendance percentages should be visually dominant.

Avoid unnecessary all-caps text.

## 8. Spacing

Use a consistent scale:

`4, 8, 12, 16, 20, 24, 32, 40, 48`

Whitespace should replace unnecessary borders wherever possible.

## 9. Buttons

### Primary

Terracotta/rose, rounded, high contrast, obvious label, subtle depth.

### Secondary

Glass or neutral surface with subtle border.

### Tertiary

Text-only or very light surface.

The primary Today action is:

**Save Today's Attendance**

It should be visually strong without taking over the screen.

## 10. Motion

Motion must improve feedback, not delay actions.

Suggested timings:

- micro interaction: 100–160ms
- control state: 140–200ms
- page transition: 180–260ms
- sheet: 220–320ms
- progress/value update: 250–450ms

Use Flutter-native animation/spring behaviour. Do not introduce multiple animation frameworks.

Avoid constant floating animations, long fades, exaggerated bounce and decorative transitions that make the app feel slow.

## 11. Mobile Bottom Navigation

Primary tabs:

**Dashboard · Today · Subjects · Calendar**

The navigation bar should be:

- floating
- translucent
- rounded
- safe-area aware
- slightly elevated
- readable

Active tab uses a subtle accent pill/glow/surface.

Optional advanced gesture:

1. pointer down on the navigation area
2. detect horizontal drag
3. indicator follows the finger
4. nearest destination is previewed
5. release commits navigation

Normal tap navigation is mandatory. The gesture must not interfere with regular content scrolling.

## 12. Dashboard

Dashboard is a light glimpse of everything.

Recommended order:

1. greeting/header
2. overall attendance card
3. today's class snapshot
4. subjects needing attention
5. upcoming event/holiday
6. quick insight
7. small trend

Do not reproduce the full Analytics page on Dashboard.

## 13. Today

Today is interaction-first.

Each class should show:

- subject
- timing if available
- optional faculty
- state: Done / Now / Upcoming when timing exists
- attendance selection

Use a clear three-state selection:

**Attended / Absent / Not Held**

The current class can have a subtle accent outline; future classes should remain quieter.

## 14. Subjects

Subjects is a management-first screen.

The main subject list should contain only what a user needs to scan:

**Subject name + attendance status/percentage + light progress indicator + action**

Tap a subject to open details.

Heavy analytics does not belong in every subject card.

## 15. Calendar

Calendar must never show all subjects inside month cells.

Use:

- compact attendance dots
- holiday markers
- event markers
- today highlight
- selected date highlight

When a date is tapped, the detailed session list appears outside the grid.

## 16. Holidays

Holidays should feel lighter and more spacious than Analytics.

Primary information:

- upcoming holidays
- multi-day breaks
- categories
- optional past section
- add/upload actions

Use both calendar and list patterns where helpful.

## 17. Analytics

Analytics is the heaviest screen but must remain readable.

The core row structure should show:

**Subject | Attendance | Attended/Conducted | Maintain 75% | Reach Target | Status**

Example language:

> You can miss up to 4 classes and still stay above 75%.

or:

> Attend the next 6 classes to reach 75%.

Charts should support decisions, not exist just to make the page look analytical.

## 18. Profile

Profile contains academic identity and configuration rather than unrelated application controls.

Sections:

- academic information
- attendance settings
- semester management
- account/security
- data export

Mobile semester switching is accessed through profile/menu surfaces.

Desktop semester switching belongs at the bottom-left sidebar.

## 19. Navigation Consistency

Every page must reuse:

- same background family
- same typography
- same accent semantics
- same card radii
- same button language
- same icon style
- same material behaviour

The user should instantly know they are still inside Attendify.

## 20. Accessibility

Required:

- sufficient contrast
- scalable text
- semantic labels
- minimum touch targets around 44×44 logical pixels
- status communicated through text/icon as well as colour
- reduced-motion support
- screen-reader navigation

When blur/transparency reduces readability, use a stronger opaque surface automatically.

## 21. Loading / Empty / Error States

Every page must have intentional states.

Examples:

**No subjects:**
> No subjects yet. Add your first subject to begin tracking attendance.

**No routine:**
> Your routine is not set up yet. Add it manually or upload a routine.

**No attendance:**
> Start marking today's classes to build your attendance history.

**Offline:**
> You're offline. Saved changes will sync when you're back online.

Never show a blank screen as a state.

## 22. Design Anti-Patterns

Do not:

- overload cards with every metric
- put eight subject names in calendar cells
- show codes such as lecture-room identifiers everywhere
- make every screen a dashboard
- use excessive blur
- use unrelated accent colours
- make animation more visible than the content
- create a separate Planner page
- create a Settings page just to increase page count

## 23. Final Visual Goal

The final product should feel like:

**warm academic productivity + refined typography + subtle nature + terracotta/rose identity + restrained liquid glass + fast micro-interactions.**

It should feel premium because of spacing, material quality, hierarchy and consistency—not because every component has an effect.
