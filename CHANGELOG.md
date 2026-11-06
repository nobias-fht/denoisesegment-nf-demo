# nobias-fht/denoisesegment: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0 - 2026-11-04

Initial release of nobias-fht/denoisesegment.

### `Added`

- Self-supervised Noise2Void training and prediction with CAREamics.
- Cellpose instance segmentation of denoised TIFF microscopy images.
- Support for a single TIFF file or a directory of TIFF images.
- Configurable CAREamics training, prediction, and Cellpose parameters.
- Docker, Apptainer, Singularity, Conda, and GPU execution profiles.
- Minimal pipeline test profile using the nf-core microscopy test image.

### `Fixed`

- Normalize single-file CAREamics prediction output before Cellpose segmentation.

### `Dependencies`

- CAREamics 0.3.5.
- Cellpose 4.0.9.
- nf-core pipeline template 4.2.1.
