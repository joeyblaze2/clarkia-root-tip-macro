# Fiji macro for automated root-tip diameter measurement in *Clarkia xantiana*

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19742959.svg)](https://doi.org/10.5281/zenodo.19742959)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Fiji/ImageJ macro that automatically measures radicle diameters at eight fixed
distances from the root tip (0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, and
2.00 mm) in calibrated grayscale images of Toluidine-Blue-stained *Clarkia
xantiana* *ssp.* *xantiana* seedlings. The macro draws perpendicular transects
from a user-traced centerline and detects the intensity transition between
stained tissue and background at each transect.

Developed as part of a study on geographic adaptation in root morphology across
*C. xantiana* populations native to different soil types.

---

## Citation

If you use this macro, please cite the archived release (preferred):

> D'Ascenzo, D. (2026). *Fiji macro for automated root-tip diameter measurement
> in Clarkia xantiana* (Version 1.0.0) [Computer software]. Zenodo.
> https://doi.org/10.5281/zenodo.19742959

And please also cite Fiji:

> Schindelin, J., Arganda-Carreras, I., Frise, E., Kaynig, V., Longair, M.,
> Pietzsch, T., … Cardona, A. (2012). Fiji: an open-source platform for
> biological-image analysis. *Nature Methods*, 9(7), 676–682.
> https://doi.org/10.1038/nmeth.2019

---

## Requirements

- **Fiji** 2.9.0 / ImageJ 1.53t or later. Download from
  https://imagej.net/software/fiji/downloads
- Input images:
  - 8-bit grayscale TIFF or PNG preferred (RGB accepted; will be converted)
  - Spatially calibrated before the macro is run (`Analyze → Set Scale`)
  - Root tip oriented so that the first 2.00 mm of radicle is visible and
    roughly straight
- No additional plugins required.

---

## Installation

1. Download `measure_root_tips.ijm` from this repository (or clone it).
2. In Fiji: **Plugins → Macros → Install…** and select the file, **or**
   place the file in `Fiji.app/macros/` and restart Fiji.
3. The macro will appear under **Plugins → Macros → Measure Root Tips**.

---

## Usage

1. Open a calibrated root-tip image in Fiji.
2. Using the **Straight Line** tool, draw a 2.00 mm centerline from the root
   tip toward the hypocotyl, following the root's long axis.
3. Run the macro. It will:
   - cast perpendicular transects at the eight fixed positions along the
     centerline,
   - detect the stained-tissue-to-background intensity transition on each
     side of the centerline,
   - record the diameter (in calibrated units) at each position to a
     tab-delimited results window.
4. Save results to disk (`File → Save As…` from the results window).

A minimal example image and expected output are provided in `examples/`.

---

## Output

The macro returns one row per image with columns:

| Column            | Description                                              |
|-------------------|----------------------------------------------------------|
| `image`           | Source image filename                                    |
| `diam_0.25mm`     | Root diameter 0.25 mm from the tip (mm)                  |
| `diam_0.50mm`     | Root diameter 0.50 mm from the tip (mm)                  |
| `diam_0.75mm`     | Root diameter 0.75 mm from the tip (mm)                  |
| `diam_1.00mm`     | Root diameter 1.00 mm from the tip (mm)                  |
| `diam_1.25mm`     | Root diameter 1.25 mm from the tip (mm)                  |
| `diam_1.50mm`     | Root diameter 1.50 mm from the tip (mm)                  |
| `diam_1.75mm`     | Root diameter 1.75 mm from the tip (mm)                  |
| `diam_2.00mm`     | Root diameter 2.00 mm from the tip (mm)                  |

---

## Known Limitations

Known failure modes:

- **Overlapping stained root hairs** at the radicle margin can cause the edge
  detector to overshoot. Mask root hairs around the radicle using Fiji's
  freehand selection tool filled with background color before running the
  macro.
- **Blurred or out-of-focus margins** can cause edge detection to fail or
  return implausible values. Remeasure affected positions manually with the
  straight-line tool.
- Approximately 0.625% of measurements in the associated study were remade
  manually for these reasons.

---

## Provenance

An initial draft of this macro was produced with assistance from Claude, a
large language model (Anthropic, 2026, https://claude.ai). The draft was
subsequently reviewed, tested against manually measured reference images,
revised, and validated by the author, who takes full responsibility for its
scientific and technical content.

---

## License

Released under the MIT License. See [`LICENSE`](LICENSE) for the full text.

---

## Contact

Dominic D'Ascenzo — dascenzod03@gmail.com
[Grinnell College]
