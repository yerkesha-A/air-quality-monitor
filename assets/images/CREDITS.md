# Nature photography

Downloaded 2026-10-13. These are independent photographs, not the user's reference screenshots.
Bundled locally; no runtime image requests or network permission required for the backgrounds.
The photographs are decorative atmosphere, not images of the currently selected city or evidence of its AQI.

## forest_sun.webp

- Source: https://images.unsplash.com/photo-1441974231531-c6227db76b6e
- Provider: Unsplash, original image identifier `photo-1441974231531-c6227db76b6e`.
- License: [Unsplash License](https://unsplash.com/license). Downloading, modifying and using
  images in commercial and non-commercial applications is permitted. The photo is embedded
  as a UI background; it is not sold as a standalone image or used in a competing photo service.
- Processing: portrait crop, 1000 × 1250, WebP quality 70; 268,972 bytes (approximately 263 KiB).

## forest_mist.webp

- Photographer: Sebastian Unrau.
- Original: https://unsplash.com/photos/v4e3JI7DDHI
- Download: https://images.unsplash.com/photo-1448375240586-882707db888b
- Independently documented attribution and license:
  https://commons.wikimedia.org/wiki/File:Bad_Pyrmont,_Deutschland_(Unsplash).jpg
- License: CC0 1.0 (published on Unsplash in 2015, before its 2017 license change);
  also available under the current Unsplash License. Commercial use and modification permitted.
- Processing: portrait crop, 1000 × 1333, WebP quality 70; approximately 141 KiB.
- Used as the full-screen History background after approval of the homepage. Not used on every screen.

The Flutter hero decodes the photograph at at most 1000 px width (about 4.8 MiB RGBA for
forest_sun), isolates repainting and uses one clipped 12 px backdrop blur. The original two compressed
photographs together add about 404 KiB to the application's assets.

## misty_hills.webp

- Source: https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05
- Provider: Unsplash, original identifier `photo-1470071459604-3b5ec3a7fe05`.
- License: https://unsplash.com/license (commercial application backgrounds permitted).
- Downloaded 2026-10-13. Real mountain, cloud and sky photograph, independently selected; not a reference screenshot.
- Optimized to 1000 × 1250, WebP quality 74. Used by the homepage hero.
- `forest_mist.webp` now supplies the full-screen History background.

Current third asset misty_hills.webp: 105,994 bytes (~104 KiB); all three photographs together ~507 KiB.
History groups its non-overlapping 10 px blurs with BackdropGroup. Actual frame-rate profiling is still pending.
