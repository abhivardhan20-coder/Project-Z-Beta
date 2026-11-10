# Project Z · Kaldran City

Launch **Play Kaldran City.cmd** or open **project.godot** in Godot 4.7.2. The city starts in Hillview Steps. Use **M** for the city atlas. Click a landmark to travel and press **Tab** to cycle the four field routes. **C** cycles the reference camera positions.

Use **WASD** to move, **Shift** to sprint, **Space** to jump, **E** to interact, **H** to heal and the **left mouse button** to swing after finding the crowbar. Enter the sedan with **E**, steer with **WASD**, brake with **Space** and stop before exiting with **E**.

The masterplan covers 64 km². The world uses its 21 districts, 24 landmark anchors, 1,766 planned footprints, 20 arterial and collector centerlines, two rail corridors, two lakes, the Westflow River and the 3.3 km runway. The map's north axis becomes negative Z. The builder fits the schematic sites to the delivered synthetic height grid and adds street infill in Hillview. The atlas area of 940 km² describes the fictional metropolitan region.

Hillview contains the playable furnished apartment and shop. Most background buildings use exterior assemblies. The runtime selects production models, surfaces and data for the city. Separate pack variants and demonstrator projects stay in the category archives. Data and provenance are in `data/city.json` and `data/pack_index.json`.

Run the in-engine verification with the console edition of Godot.

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --verify-city
```
