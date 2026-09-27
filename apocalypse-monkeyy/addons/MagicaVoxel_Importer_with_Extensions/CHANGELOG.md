# Changelog

All notable changes to this project are documented in this file.

## [1.3.0] - 2026-08-02

Modified by bakacandy.


### Added

- Added a `PackedScene` importer that preserves the MagicaVoxel node hierarchy and node names.
- Added automatic `AnimationPlayer` generation for animated VOX files.
- Added discrete mesh tracks for MagicaVoxel shape-model keyframes.
- Added transform tracks for MagicaVoxel transform keyframes.
- Added import options for animation inclusion, playback FPS, looping, and autoplay.
- Added an `OriginsToGeometry` option that centers each model origin on its own generated geometry while preserving scene placement.
- Added a reimport safeguard that closes an open VOX source scene before Godot replaces its imported scene data.
- Added automatic Import dock refresh after the selected VOX file is reimported.
- Added a foldable `VOX Info` panel below the import options.
- Added lazily generated per-node and per-animation-frame VOX dimensions, voxel, vertex, triangle, and surface statistics.

### Changed

- Made `MagicaVoxel Scene` the default importer for VOX files.
- Improved shared VOX parsing so mesh, mesh-library, and scene importers use the same parsed data.
- Optimized greedy mesh generation to process visible faces without repeatedly scanning empty voxel space.
- Assigned stable names to generated meshes and materials for clearer imported resources.
- Placed the generated `AnimationPlayer` as the first child of imported scene roots.
- Preserved each VOX file's `VOX Info` fold state while the editor remains open.
- Discarded generated VOX statistics whenever the information panel is folded.

### Fixed

- Fixed VOX scene graph imports being flattened into a single mesh.
- Fixed animated VOX files importing only their first visible model state.
- Fixed conditional animation import options remaining stale in the Import dock after reimport.
- Reduced the risk of an editor crash when reimporting an open VOX source scene in Godot 4.7.

## Project Lineage

### [1.2.0-godot4] - 2023-01-04

Maintained by Violgamba.

- Forked `MagicaVoxel Importer with Extensions` for Godot 4.0 as `MagicaVoxel importer with extensions++`.
- Added hidden-layer filtering and layer-order rendering.
- Added first-keyframe-only rendering support.
- Added a MeshLibrary importer for multiple MagicaVoxel keyframes.
- Added `FramedMeshInstance` for keyframe animation.

### [1.2.0] - 2019-07-03

Created by CloneDeath.

- Released `MagicaVoxel Importer with Extensions` for Godot 3.1.
- Added support for complete MagicaVoxel scene graphs, including groups, transforms, and reference copies.
- Added basic material support.
- Added greedy mesh generation.
- Added snap-to-ground support.

### Earlier Code Lineage

- CloneDeath's repository was forked from `n3rdw1z4rd/vox-importer`.
- `n3rdw1z4rd/vox-importer` identifies itself as an adaptation of `MagicaVoxel-Importer` by Scayze.
- The inherited metadata credits `vox-importer` to JohnCWakley, and the bundled MIT license retains the JohnCWakley copyright notice.
