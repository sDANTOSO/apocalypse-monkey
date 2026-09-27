# MagicaVoxel Importer with Extensions

Imports MagicaVoxel `.vox` files into Godot as meshes, mesh libraries, or node-preserving `PackedScene` resources.

The scene importer preserves MagicaVoxel node names and hierarchy, and animated VOX files can be imported with a generated `AnimationPlayer`.

## Features

- Imports `.vox` files as a `PackedScene`, `Mesh`, or `MeshLibrary`.
- Uses `MagicaVoxel Scene` as the default importer.
- Preserves MagicaVoxel scene hierarchy, node names, groups, transforms, rotations, and reference copies in scene imports.
- Generates an `AnimationPlayer` as the first child of an imported scene when animation data is available.
- Imports discrete shape-model mesh tracks and transform tracks.
- Supports configurable animation FPS, looping, and autoplay.
- Supports greedy or culled mesh generation, import scaling, snap-to-ground, and per-model geometry-centered origins.
- Refreshes the Import dock after a selected VOX file is reimported so conditional animation options remain current.
- Protects open imported VOX scene tabs during reimport to reduce invalid-resource editor crashes in Godot 4.7.

## Installation

Copy `MagicaVoxel_Importer_with_Extensions` into your project's `addons` directory, then enable **MagicaVoxel Importer with Extensions** under **Project > Project Settings > Plugins**.

Select a `.vox` file in the FileSystem dock to configure its importer. New VOX files use **MagicaVoxel Scene** by default; the importer can still be changed to **MagicaVoxel Mesh** or **MagicaVoxel MeshLibrary** in the Import dock.

## Scene Import Options

- **Scale**: Sets the imported voxel scale.
- **GreedyMeshGenerator**: Uses greedy meshing when enabled; otherwise uses the culled mesh generator.
- **SnapToGround**: Moves the imported scene content onto the ground plane.
- **OriginsToGeometry**: Places each generated model origin at the center of its own mesh geometry while preserving its scene placement.
- **ImportAnimation**: Generates animation tracks when the VOX file contains animated data.
- **AnimationFPS**: Sets the playback rate used for MagicaVoxel frame IDs.
- **AnimationLoop**: Makes the generated animation loop.
- **AnimationAutoplay**: Starts the generated animation automatically.

## VOX Import Information

The Import dock includes a foldable **VOX Info** panel below the import options. It reports the imported mesh-node count, loaded mesh-resource count, animation frame entries, VOX model IDs and dimensions, voxel counts, vertices, triangles, and surfaces.

Animated shape meshes are listed separately by node and frame. Statistics are generated only when the panel is expanded and are discarded when it is folded. The fold state is retained for each selected VOX path while the editor remains open.

## Reimport Notes

When a selected VOX file finishes reimporting, the plugin refreshes its Import dock selection so animation-dependent options and VOX information reflect the new file contents. If the imported VOX scene itself is open in an editor tab, the plugin closes that tab before replacement to avoid retaining invalid imported resources.

## Project Lineage and Contributions

This project has evolved through several adaptations and forks. The people below are listed according to the contribution records retained by the inherited project metadata and upstream repositories.

### Scayze

- Created the earlier [`MagicaVoxel-Importer`](https://github.com/scayze/MagicaVoxel-Importer) Godot plugin.
- Provided the original MagicaVoxel VOX-to-mesh importer foundation used by later adaptations.

### n3rdw1z4rd

- Adapted Scayze's importer as [`vox-importer`](https://github.com/n3rdw1z4rd/vox-importer) for Godot 3.1.
- Added import scaling and XZ centering based on the MagicaVoxel model resolution.
- This is the repository from which CloneDeath's repository was directly forked.

### JohnCWakley

- Identified by the inherited project metadata as the author of `vox-importer`.
- Retained as the 2019 copyright holder in the inherited MIT license.
- The exact relationship between this attribution and the upstream GitHub account history is not established by the retained files, so this entry preserves the original attribution without claiming direct participation in later forks.

### CloneDeath

- Created [`MagicaVoxel Importer with Extensions`](https://github.com/CloneDeath/MagicaVoxel-Importer-with-Extensions) for Godot 3.1.
- Added support for complex MagicaVoxel scene graphs, including groups, transforms, rotations, flips, and reference copies.
- Added coordinate-space conversion, basic material support, greedy mesh generation, and snap-to-ground support.

### Violgamba

- Forked CloneDeath's project as [`MagicaVoxel importer with extensions++`](https://godotengine.org/asset-library/asset/1587) for Godot 4.
- Added hidden-layer filtering, layer-order rendering, and first-keyframe-only rendering.
- Added a MeshLibrary importer for multiple MagicaVoxel keyframes.
- Added `FramedMeshInstance` for animating imported keyframes.

### bakacandy

- Added a node-preserving `PackedScene` importer and made Scene import the default for VOX files.
- Added generated `AnimationPlayer` resources with discrete mesh tracks and transform tracks.
- Added animation import, FPS, loop, and autoplay options.
- Added per-model geometry-centered origin support while preserving scene placement.
- Added automatic Import dock refresh after reimporting the selected VOX file.
- Added a foldable, lazily generated VOX information panel with per-frame mesh statistics.
- Added stable generated resource names and shared VOX parsing across importer types.
- Added a safeguard for reimporting an open VOX source scene in Godot 4.7.
- Optimized greedy mesh generation to avoid repeatedly scanning empty voxel space.

See [`CHANGELOG.md`](../CHANGELOG.md) for release-specific details.

## License

Distributed under the MIT License. The original license text and copyright notice are retained in [`LICENSE`](LICENSE).
