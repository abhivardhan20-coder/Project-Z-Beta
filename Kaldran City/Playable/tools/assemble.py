"""Build the Godot city from the delivered ZIPs and the schematic masterplan."""

from collections import defaultdict
import csv
from io import BytesIO, StringIO
import json
import math
from pathlib import Path, PurePosixPath
import random
import re
import struct
import sys
import zipfile

import numpy as np
from PIL import Image


PROJECT = Path(__file__).resolve().parents[1]
DESKTOP = Path.home() / "OneDrive/Desktop/Project Z (Godot)"
PACKS = DESKTOP / "Kaldran City"
DATA = PROJECT / "data"
CONTENT = PROJECT / "content"
SIZE = 1025
STEP = 8000 / (SIZE - 1)
TILE = 250
RNG = random.Random(18109)

PREFERRED = {
    1: "Ridge_Near.glb", 11: "Hillview_250m_Pilot.glb", 43: "main_shell_LOD0.glb",
    55: "Facade_Straight_Intact_LOD0.glb", 57: "16F_Office_Tower_LOD0.glb",
    67: "Apartment_Ground_Lobby.glb", 82: "Residential_Block_40m_LOD0.glb",
    83: "Shop_Room.glb", 85: "Arcade_Connected_Passage_Sample.glb",
    97: "hospital_exterior_LOD0.glb", 111: "Central_Arch_Bay_LOD0.glb",
    112: "stone_front_LOD0.glb", 126: "Terminal_Roof_Two_Bay_LOD0.glb",
    127: "front_facade_LOD0.glb", 133: "control_tower_LOD0.glb", 164: "Sedan_Complete.glb",
    198: "Plane_Green_LOD0.glb", 199: "Pine_Mature_A_LOD0.glb",
    237: "Playground_Static_Assembly.glb", 325: "sofa_2seat.glb",
    326: "Survivor_Rigged.glb", 327: "Common_Infected_Rigged.glb",
    328: "Cache_Body.glb", 329: "research_rooms_LOD0.glb", 330: "Museum_Gallery.glb",
}

# Additional pieces needed in the assembled sites and the playable interactions.
EXTRAS = {
    "crowbar": (328, "Crowbar.glb"), "cache_lid": (328, "Cache_Lid.glb"),
    "dressing": (328, "Field_Dressing.glb"), "medkit": (328, "Medkit.glb"),
    "backpack": (328, "Backpack_Closed.glb"), "crate": (328, "Medical_Crate.glb"),
    "tower_low": (57, "08F_Office_Tower_LOD0.glb"),
    "tower_high": (57, "24F_Office_Tower_LOD0.glb"),
    "fir": (199, "Fir_Mature_A_LOD0.glb"), "alder": (198, "Alder_Green_LOD0.glb"),
    "roof_bay": (111, "Central_Arch_Bay_LOD0.glb"),
    "civic_flag": (300, "CivicFlag_civic.glb"), "arrivals_board": (300, "Arrivals_LED.glb"),
    "stalled_bus": (312, "Stalled_City_Bus.glb"), "stretcher": (313, "Stretcher_LOD0.glb"),
    "airport_hut": (314, "Checkpoint_Guard_Hut.glb"), "baggage_tug": (315, "Ground_Baggage_Tug_LOD0.glb"),
    "tape": (280, "Caution_Tape_3m.glb"), "cracked_glass": (270, "Transit_glass_shatter_insert_cracked.glb"),
    "wheel_stop": (291, "Wheel_Stop_Block.glb"),
    "apartment_block": (82, "Residential_Block_64m_LOD0.glb"),
    "station_glazing": (112, "Station_Tall_Arched_Glazing.glb"),
}

LANDMARKS = {
    "P01": [(43, 0, 0, 0), (44, -44, 16, 0), (50, 0, 29, 0), (49, 35, -24, 0)],
    "P02": [(45, 0, 0, 0), (47, 0, 12, 0), (27, 22, -10, 0), (243, -21, 12, 0)],
    "P03": [(112, 0, -12, 0), (111, 0, 20, 0), (111, 0, 37, 0), (114, 0, 4, 0),
            (116, 34, 47, 0), (117, 42, 48, 0), (121, -17, 4, 0), (122, -27, 15, 0)],
    "P04": [(127, 0, 0, 0), (126, 0, 14, 0), (126, 36, 14, 0), (128, 4, 9, 0),
            (130, 36, 16, 0), (132, 22, 53, 90), (136, 45, 95, 90), (141, 0, -33, 0),
            (142, -41, 47, 0), (135, 42, 74, 0)],
    "P05": [(146, 0, 0, 0), (147, 20, -13, 0), (148, -19, 7, 0), (151, 25, 14, 0),
            (139, 13, 14, 0), (157, -23, 16, 0), (161, 25, -5, 0)],
    "P06": [(76, -24, 10, 45), (82, 45, -42, 45), (181, -12, 8, 45), (180, 7, 13, 0),
            (156, -9, 7, 60), (81, 22, 16, 30), (154, -12, -16, 45)],
    "P07": [(97, 0, 0, 0), (98, -25, 26, 0), (99, 18, 25, 0), (102, 0, 20, 0),
            (147, 28, -24, 0), (154, -8, -29, 0), (148, 21, -21, 0)],
    "P08": [(329, 0, 0, 0), (56, -37, 13, 0), (57, 48, 22, 0), (192, 8, -29, 0)],
    "P09": [(239, 0, 0, 0), (240, 45, 8, 90), (240, -45, 8, -90), (241, 0, -53, 0)],
    "P10": [(39, 8, 13, 0), (25, -21, -10, 90)],
    "P11": [(53, 0, 0, 0), (150, -13, 0, 0), (157, 16, 10, 0), (158, 7, -7, 0)],
    "P12": [(120, 0, 0, 0), (21, -14, 10, 0), (166, 7, -6, 90), (196, 5, 7, 0)],
    "P13": [(3, 17, -11, 0), (8, 0, 0, 45), (181, -2, 5, 0)],
    "P14": [(147, 0, 0, 0), (151, 12, 5, 0), (154, -11, 0, 90), (156, -5, -7, 0)],
    "P15": [(57, 0, 0, 0), ("tower_high", -38, 42, 15), ("tower_low", 42, 31, 0),
            (56, 0, -20, 0), (58, 31, 15, 90)],
    "P16": [(85, 0, 0, 0), (87, -16, 12, 0), (88, 18, 12, 0), (89, 8, -12, 90)],
    "P17": [(133, 0, 0, 0), (142, -23, -5, 0)],
    "P18": [(230, 0, 0, 0), (225, 37, 21, 90), (232, 20, 57, 0), (119, 32, 58, 0),
            (226, 20, 12, 0), (227, 20, 30, 90), (228, -11, 15, 0)],
    "P19": [(217, 0, 0, 0), (7, -19, 15, 15), (218, 17, 16, 0), (213, 32, -17, 0)],
    "P20": [(8, 0, 0, 0), (181, 3, 8, 0), (212, 10, 6, 0)],
    "P21": [(109, 0, 0, 0), (154, -12, -10, 75)],
    "P22": [(41, 0, 0, 0), (23, -21, 13, 90), (221, 41, -42, 0)],
    "P23": [(237, 0, 0, 0), (181, -9, -12, 90), (197, 14, 9, 0)],
    "P24": [(54, 0, 0, 0), (330, 0, 10, 0), (117, 31, 17, 90), (300, -7, -13, 0)],
}


def write_json(path, value):
    path.write_text(json.dumps(value, separators=(",", ":"), ensure_ascii=False), encoding="utf-8")


def read_named(archive, suffix):
    return archive.read(next(name for name in archive.namelist() if name.endswith(suffix)))


def read_json(archive, suffix):
    return json.loads(read_named(archive, suffix))


def discover():
    groups = defaultdict(list)
    for path in sorted(PACKS.glob("*/*.zip")):
        number = int(path.name[4:8])
        groups[number].append(path)
    if len(groups) != 228:
        raise RuntimeError(f"Expected 228 asset IDs, found {len(groups)}")
    return groups


def glb_parts(blob):
    signature, version, length, js_size, kind = struct.unpack_from("<4sIII4s", blob)
    if (signature, version, length, kind) != (b"glTF", 2, len(blob), b"JSON"):
        raise ValueError("Invalid GLB")
    model = json.loads(blob[20:20 + js_size])
    return model, blob[28 + js_size:] if len(blob) >= 28 + js_size else b""


def glb_bounds(model):
    points = []
    nodes = model.get("nodes", [])
    meshes = model.get("meshes", [])
    accessors = model.get("accessors", [])
    def visit(index, parent):
        node = nodes[index]
        if "matrix" in node:
            local = np.array(node["matrix"]).reshape(4, 4).T
        else:
            x, y, z, w = node.get("rotation", [0, 0, 0, 1])
            local = np.array([[1 - 2*y*y - 2*z*z, 2*x*y - 2*z*w, 2*x*z + 2*y*w, 0],
                              [2*x*y + 2*z*w, 1 - 2*x*x - 2*z*z, 2*y*z - 2*x*w, 0],
                              [2*x*z - 2*y*w, 2*y*z + 2*x*w, 1 - 2*x*x - 2*y*y, 0],
                              [0, 0, 0, 1]], dtype=float)
            local[:3, :3] *= np.array(node.get("scale", [1, 1, 1]))
            local[:3, 3] = node.get("translation", [0, 0, 0])
        matrix = parent @ local
        if "mesh" in node:
            for prim in meshes[node["mesh"]]["primitives"]:
                accessor = accessors[prim["attributes"]["POSITION"]]
                if "min" not in accessor:
                    continue
                lo, hi = accessor["min"], accessor["max"]
                corners = [[a, b, c, 1] for a in (lo[0], hi[0]) for b in (lo[1], hi[1]) for c in (lo[2], hi[2])]
                points.extend((matrix @ np.array(corners).T).T[:, :3])
        for child in node.get("children", []):
            visit(child, matrix)
    for node in model.get("scenes", [{}])[model.get("scene", 0)].get("nodes", []):
        visit(node, np.eye(4))
    if not points:
        return [0, 0, 0, 1, 1, 1]
    return np.round(np.r_[np.min(points, axis=0), np.max(points, axis=0)], 4).tolist()


def compact_glb(archive, name, limit):
    model, binary = glb_parts(archive.read(name))
    data = bytearray(binary)
    views = model.setdefault("bufferViews", [])
    names = set(archive.namelist())
    for image in model.get("images", []):
        if "uri" in image:
            uri = image["uri"]
            if uri.startswith("data:"):
                continue
            import posixpath
            path = posixpath.normpath(posixpath.join(posixpath.dirname(name), uri))
            if path not in names:
                matches = [n for n in names if PurePosixPath(n).name == PurePosixPath(uri).name]
                if len(matches) != 1:
                    raise ValueError(f"Cannot resolve image {uri} for {name}")
                path = matches[0]
            payload = archive.read(path)
        elif "bufferView" in image:
            view = views[image["bufferView"]]
            start = view.get("byteOffset", 0)
            payload = binary[start:start + view["byteLength"]]
        else:
            continue
        if image.get("name") == "wing_lower_BaseColor":
            try:
                Image.open(BytesIO(payload)).verify()
            except (OSError, SyntaxError):
                # The delivered jet has one incomplete PNG in every LOD. Reuse the
                # intact upper-wing finish in the compiled model, keeping the ZIP intact.
                payload = read_named(archive, "/wing_upper_BaseColor.png")
                image["uri"] = "recovered-wing-surface.png"
        try:
            source = Image.open(BytesIO(payload))
            if "uri" not in image and max(source.size) <= limit:
                continue
            source.thumbnail((limit, limit), Image.Resampling.LANCZOS)
            handle = BytesIO()
            source.save(handle, format="PNG", optimize=False)
            payload = handle.getvalue()
        except OSError:
            if "uri" not in image:
                continue
        while len(data) % 4:
            data.append(0)
        image.pop("uri", None)
        image["bufferView"] = len(views)
        image["mimeType"] = "image/jpeg" if payload.startswith(b"\xff\xd8") else "image/png"
        views.append({"buffer": 0, "byteOffset": len(data), "byteLength": len(payload)})
        data.extend(payload)
    # Remove replaced image ranges without changing any accessor-relative offsets.
    alive = set()
    for accessor in model.get("accessors", []):
        if "bufferView" in accessor:
            alive.add(accessor["bufferView"])
        for part in accessor.get("sparse", {}).values():
            if isinstance(part, dict) and "bufferView" in part:
                alive.add(part["bufferView"])
    alive.update(image["bufferView"] for image in model.get("images", []) if "bufferView" in image)
    if not model.get("extensionsUsed") and model.get("buffers"):
        new_data = bytearray()
        for i, view in enumerate(views):
            if i not in alive:
                view["byteOffset"] = 0
                view["byteLength"] = 1
                continue
            while len(new_data) % 4:
                new_data.append(0)
            start = view.get("byteOffset", 0)
            view["byteOffset"] = len(new_data)
            new_data.extend(data[start:start + view["byteLength"]])
        data = new_data
    if model.get("buffers"):
        model["buffers"][0]["byteLength"] = len(data)
    js = json.dumps(model, separators=(",", ":")).encode()
    js += b" " * (-len(js) % 4)
    data.extend(b"\0" * (-len(data) % 4))
    body = struct.pack("<I4s", len(js), b"JSON") + js
    if data:
        body += struct.pack("<I4s", len(data), b"BIN\0") + data
    return struct.pack("<4sII", b"glTF", 2, 12 + len(body)) + body, glb_bounds(model)


def select_model(paths, preferred=None):
    options = []
    for path in paths:
        with zipfile.ZipFile(path) as archive:
            for entry in archive.infolist():
                name = entry.filename
                base = PurePosixPath(name).name.lower()
                if not base.endswith(".glb") or re.search(r"fixture|test|collision|^col_|/qa/", name.lower()):
                    continue
                if preferred and not base.endswith(preferred.lower()):
                    continue
                score = (30 * ("lod0" in base) + 20 * ("k3d-" in base) +
                         10 * any(k in base for k in ("complete", "assembly", "hero", "intact")) -
                         40 * any(k in base for k in ("lod1", "lod2", "lod3", "broken", "damage", "overturned")) +
                         8 * ("/glb/" in ("/" + name.lower())) - 20 * ("/godot/" in ("/" + name.lower())))
                options.append((score, min(entry.file_size, 18_000_000), path, name))
    return max(options, default=None)


def copy_model(paths, key, preferred, limit=640):
    selection = select_model(paths, preferred)
    if selection is None and preferred:
        selection = select_model(paths)
    if selection is None:
        return None
    _, _, path, member = selection
    with zipfile.ZipFile(path) as archive:
        blob, bounds = compact_glb(archive, member, limit)
    target = CONTENT / "models" / f"{key}.glb"
    target.write_bytes(blob)
    return {"path": f"res://content/models/{key}.glb", "bounds": bounds, "source": member}


def import_walkable_site(paths, key, scene_name, ignored):
    with zipfile.ZipFile(paths[0]) as archive:
        scene = read_named(archive, scene_name).decode("utf-8-sig")
        scene = re.sub(r"(?m)^\[ext_resource type=\"Script\"[^\n]*\]\n|^script = ExtResource\([^\n]*\)\n", "", scene)
        sections = re.split(r"(?=^\[node )", scene, flags=re.M)
        graph = {}
        external = {}
        for resource, identifier in re.findall(r'path="res://(GLB/[^"]+)" id="([^"]+)"', sections[0]):
            external[identifier] = resource
        keep = [re.sub(r"(?m)^\[ext_resource type=\"PackedScene\"[^\n]*\]\n", "", sections[0])]
        for section in sections[1:]:
            header = section.splitlines()[0]
            name = re.search(r'name="([^"]+)"', header).group(1)
            parent = re.search(r'parent="([^"]+)"', header)
            if name in ignored or (parent and parent.group(1).split("/")[0] in ignored):
                continue
            instance = re.search(r' instance=ExtResource\("([^"]+)"\)', header)
            if instance and instance.group(1) in external:
                anchor = name if parent is None or parent.group(1) == "." else parent.group(1) + "/" + name
                graph[anchor] = f"res://content/{key}/" + external[instance.group(1)]
                section = section.replace(instance.group(0), ' type="Node3D"', 1)
            section = re.sub(r"Transform3D\(Basis\(\), Vector3\(([^)]+)\)\)", r"Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, \1)", section)
            keep.append(section)
        site = CONTENT / key
        site.mkdir(exist_ok=True)
        (site / "GLB").mkdir(exist_ok=True)
        for member in re.findall(r'path="res://(GLB/[^"]+)"', scene):
            if "--layout-only" in sys.argv and (site / member).is_file():
                continue
            blob, _ = compact_glb(archive, member, 768)
            (site / member).write_bytes(blob)
        output = "".join(keep).replace("res://GLB/", f"res://content/{key}/GLB/")
        (site / "site.tscn").write_text(output, encoding="utf-8")
        return {"path": f"res://content/{key}/site.tscn", "children": graph}


def asset_intake(groups):
    catalog = {}
    intake = {}
    for number, paths in sorted(groups.items()):
        key = f"{number:04d}"
        category = paths[0].parent.name[:2]
        model = None
        if int(category) < 19 or number in PREFERRED:
            model = copy_model(paths, key, PREFERRED.get(number), 768 if number in PREFERRED else 512)
        if model:
            catalog[key] = model
        intake[key] = {"source": [p.name for p in paths], "category": category, "representative": model}
        if number % 25 == 0:
            print(f"Compiled asset packs through K3D-{number:04d}", flush=True)
    supplemental_assets(groups, catalog, intake)
    catalog["apartment"] = import_walkable_site(groups[67], "apartment", "Apartment_Walk_Test.tscn",
                           {"Debug_Camera", "Sun", "COL_CapsuleTester", "WorldEnvironment", "UI", "Environment"})
    catalog["shop"] = import_walkable_site(groups[83], "shop", "Shop_Entry_Test.tscn",
                      {"Player", "Camera3D", "Sun", "WorldEnvironment", "UI", "Environment"})
    write_json(DATA / "catalog.json", catalog)
    write_json(DATA / "pack_index.json", intake)
    return catalog, intake


def supplemental_assets(groups, catalog, intake):
    for key, (number, member) in EXTRAS.items():
        if key not in catalog:
            model = copy_model(groups[number], key, member)
            if model:
                catalog[key] = model
    surface_needles = {
        268: ("asphalt", "basecolor"), 288: ("concrete_neutral", "basecolor"),
        285: ("limestone", "basecolor"), 286: ("glass", "basecolor"),
        293: ("basecolor",), 295: ("basecolor",), 296: ("basecolor",),
        297: ("basecolor",), 298: ("basecolor",), 299: ("basecolor",),
        301: ("basecolor",), 302: ("basecolor",),
        271: ("rain_streak", "basecolor"), 272: ("soot_sparse",), 273: ("hazenoise",),
        274: ("clouddensity",), 275: ("fog_density_mask",), 276: ("dry_basecolor",),
        278: ("small_stain_basecolor",), 279: ("backuplight_basecolor",), 281: ("facade_basecolor",),
        282: ("lensemissionmask",),
    }
    for number, needles in surface_needles.items():
        if intake[f"{number:04d}"].get("surface"):
            continue
        with zipfile.ZipFile(groups[number][0]) as archive:
            candidates = [n for n in archive.namelist() if n.lower().endswith(".png") and
                          not re.search(r"preview|/qa/", n.lower()) and all(k in n.lower() for k in needles)]
            if candidates:
                path = CONTENT / "surfaces" / f"{number:04d}.png"
                image = Image.open(BytesIO(archive.read(sorted(candidates)[0])))
                image.thumbnail((1024, 1024))
                image.save(path)
                intake[f"{number:04d}"]["surface"] = f"res://content/surfaces/{path.name}"


def terrain_grid(groups):
    with zipfile.ZipFile(groups[323][0]) as archive:
        city = np.frombuffer(read_named(archive, "/City_Height_R32F.raw"), "<f4").reshape(257, 257)
        hill = np.frombuffer(read_named(archive, "/Hillview_Height_R32F.raw"), "<f4").reshape(251, 251)
        metadata = read_json(archive, "Terrain_Metadata.json")
    coordinates = np.linspace(0, 256, SIZE)
    x0 = np.floor(coordinates).astype(int)
    x1 = np.minimum(x0 + 1, 256)
    fraction = coordinates - x0
    east = city[:, x0] * (1 - fraction) + city[:, x1] * fraction
    raster = (east[x0, :] * (1 - fraction[:, None]) + east[x1, :] * fraction[:, None]).astype("float32")
    ix = np.where((np.linspace(-4000, 4000, SIZE) >= -2635) & (np.linspace(-4000, 4000, SIZE) <= -2385))[0]
    iz = np.where((np.linspace(-4000, 4000, SIZE) >= 1005) & (np.linspace(-4000, 4000, SIZE) <= 1255))[0]
    east_h = -4000 + ix * STEP + 2635
    south_h = -4000 + iz * STEP - 1005
    def interp(values):
        first = np.floor(values).astype(int)
        return first, np.minimum(first + 1, 250), values - first
    ax, bx, fx = interp(east_h)
    az, bz, fz = interp(south_h)
    h = hill[:, ax] * (1-fx) + hill[:, bx] * fx
    raster[np.ix_(iz, ix)] = h[az, :] * (1-fz[:, None]) + h[bz, :] * fz[:, None]
    return raster, metadata


def sample(grid, x, z):
    x, z = np.clip((np.asarray(x) + 4000) / STEP, 0, SIZE-1), np.clip((np.asarray(z) + 4000) / STEP, 0, SIZE-1)
    i, j = np.floor(x).astype(int), np.floor(z).astype(int)
    k, l = np.minimum(i + 1, SIZE-1), np.minimum(j + 1, SIZE-1)
    a, b = x-i, z-j
    return (grid[j, i]*(1-a)*(1-b) + grid[j, k]*a*(1-b) + grid[l, i]*(1-a)*b + grid[l, k]*a*b)


def patch_grid(grid, x, z, width, depth, height, feather):
    x0, x1 = np.clip(np.array([(x-width/2-feather+4000)/STEP, (x+width/2+feather+4000)/STEP]).astype(int) + [0, 2], 0, SIZE)
    z0, z1 = np.clip(np.array([(z-depth/2-feather+4000)/STEP, (z+depth/2+feather+4000)/STEP]).astype(int) + [0, 2], 0, SIZE)
    xx = np.arange(x0, x1) * STEP - 4000
    zz = np.arange(z0, z1)[:, None] * STEP - 4000
    distance = np.maximum(np.abs(xx-x)-width/2, np.abs(zz-z)-depth/2)
    blend = np.clip(1-distance/feather, 0, 1)
    grid[z0:z1, x0:x1] += (height-grid[z0:z1, x0:x1])*blend


def grade_corridor(grid, points, width, altitude=None, bank=False):
    if altitude is None:
        altitude = sample(grid, [p[0] for p in points], [p[1] for p in points])
    for (a, b, h1, h2) in zip(points, points[1:], altitude, altitude[1:]):
        dx, dz = b[0]-a[0], b[1]-a[1]
        half = width/2
        edge = half + (22 if not bank else 12)
        x0, x1 = np.clip(np.array([(min(a[0],b[0])-edge+4000)/STEP,(max(a[0],b[0])+edge+4000)/STEP]).astype(int)+[0,2],0,SIZE)
        z0, z1 = np.clip(np.array([(min(a[1],b[1])-edge+4000)/STEP,(max(a[1],b[1])+edge+4000)/STEP]).astype(int)+[0,2],0,SIZE)
        xx = np.arange(x0,x1)*STEP-4000-a[0]
        zz = np.arange(z0,z1)[:,None]*STEP-4000-a[1]
        t = np.clip((xx*dx+zz*dz)/max(0.01,dx*dx+dz*dz),0,1)
        distance = np.hypot(xx-t*dx,zz-t*dz)
        blend = np.clip((edge-distance)/(edge-half),0,1)
        region = grid[z0:z1,x0:x1]
        region += ((h1+(h2-h1)*t)-region)*blend


def densify(points, interval):
    result = []
    for a, b in zip(points, points[1:]):
        count = max(1, math.ceil(math.dist(a, b)/interval))
        result += [(a[0]+(b[0]-a[0])*i/count, a[1]+(b[1]-a[1])*i/count) for i in range(count)]
    return result + [tuple(points[-1])]


def world_point(point):
    return (point[0], -point[1])


def crossing(a, b, c, d):
    rx, rz = b[0]-a[0],b[1]-a[1]
    sx, sz = d[0]-c[0],d[1]-c[1]
    denominator = rx*sz-rz*sx
    if abs(denominator)<0.001:
        return None
    qx,qz = c[0]-a[0],c[1]-a[1]
    t,u = (qx*sz-qz*sx)/denominator,(qx*rz-qz*rx)/denominator
    if 0 <= t < 1 and 0 <= u < 1:
        return (a[0]+t*rx,a[1]+t*rz)
    return None


def fit_bridges(roads, river, grid, chunks):
    crossings = defaultdict(list)
    for key,kind,width,route in roads:
        for a,b in zip(route,route[1:]):
            for c,d in zip(river,river[1:]):
                center = crossing(a,b,c,d)
                if center is None:
                    continue
                x,z = center
                length = math.dist(a,b)
                vx,vz = (b[0]-a[0])/length,(b[1]-a[1])/length
                positions=[(x+s*vx,z+s*vz) for s in (-78,-34,34,78)]
                left, right = float(sample(grid,*positions[0])),float(sample(grid,*positions[-1]))
                deck = max(left,right,float(sample(grid,x,z)))+0.48
                elevations = [left+0.10,deck,deck,right+0.10]
                chunks[tile(x,z)]["routes"].append([key,"bridge",width,positions,elevations])
                crossings[key].append(center)
    return crossings


def tile(x, z):
    return f"{max(0,min(31,int((x+4000)//TILE)))}_{max(0,min(31,int((z+4000)//TILE)))}"


def inside(x, z, polygon):
    result = False
    for a, b in zip(polygon, polygon[1:]+polygon[:1]):
        if (a[1]>z) != (b[1]>z) and x < (b[0]-a[0])*(z-a[1])/(b[1]-a[1])+a[0]:
            result = not result
    return result


def make_world(groups, catalog, intake):
    with zipfile.ZipFile(next((DESKTOP/"New Assets").glob("*Masterplan*.zip"))) as archive:
        plan = read_json(archive, "Masterplan_Layout.json")
        footprints = list(csv.DictReader(StringIO(read_named(archive,"Building_Footprints.csv").decode("utf-8-sig"))))
    grid, meta = terrain_grid(groups)
    chunks = defaultdict(lambda: {"buildings": [], "props": [], "routes": [], "groves": []})
    poi = {p["id"]: p for p in plan["landmarks"]}
    districts = {d["id"]: d for d in plan["districts"]}
    roads = [(r["id"],r["class"],r["nominal_width_m"],[world_point(p) for p in r["centerline_xz_m"]]) for r in plan["arterials"]]
    rail = [(r["id"],"rail",8,[world_point(p) for p in r["centerline_xz_m"]]) for r in plan["rail_lines"]]
    runway = [world_point(p) for p in plan["runway"]["centerline_from_to_xz_m"]]
    air_y = float(np.mean(sample(grid,[p[0] for p in runway],[p[1] for p in runway])))
    grade_corridor(grid, runway, 76, [air_y, air_y])
    river = densify([world_point(p) for p in plan["westflow_river_centerline_xz_m"]], 35)
    river_heights = sample(grid,[p[0] for p in river],[p[1] for p in river])
    river_heights = np.convolve(np.pad(river_heights, (3,3),mode="edge"),np.ones(7)/7,mode="valid")
    grade_corridor(grid, river, 31, river_heights-1.35, bank=True)
    lakes=[]
    for lake in plan["lakes"]:
        poly = [world_point(p) for p in lake["outline_xz_m"]]
        y = float(np.percentile(sample(grid,[p[0] for p in poly],[p[1] for p in poly]),32))
        for j in range(max(0,int((min(p[1] for p in poly)+4000)/STEP)),min(SIZE,int((max(p[1] for p in poly)+4000)/STEP)+2)):
            for i in range(max(0,int((min(p[0] for p in poly)+4000)/STEP)),min(SIZE,int((max(p[0] for p in poly)+4000)/STEP)+2)):
                if inside(i*STEP-4000,j*STEP-4000,poly):
                    grid[j,i] = min(grid[j,i],y-0.8)
        lakes.append([poly,round(y,3)])
    for key, p in poi.items():
        if key in {"P06","P10","P13","P19","P20","P22"}:
            continue
        x,z=world_point(p["xz_m"])
        width, depth = (176,140) if key in {"P04","P09"} else (108,88)
        patch_grid(grid,x,z,width,depth,float(sample(grid,x,z)),23)
    for _, kind, width, points in roads+rail:
        detail = densify(points,32)
        grade_corridor(grid, detail, width+5)
    pilot = [world_point(p) for p in meta["hillview"]["road_center_start_and_end_east_north"]]
    roads.append(("HV","local",6.6,pilot))
    roads.append(("RUNWAY","runway",65,runway))
    p06 = world_point(poi["P06"]["xz_m"])
    p23 = world_point(poi["P23"]["xz_m"])
    # The hillside pedestrian route follows the authored access corridor and park edge.
    roads.append(("M01-HV","walk",2.8,[p06,(-2496,1087),(-2495,1012),(-2524,947),p23]))
    bridges=fit_bridges(roads+rail,river,grid,chunks)
    grade_corridor(grid,river,30,river_heights-1.35,bank=True)
    special = []
    for name,pad in zip(("apartment","shop"),meta["hillview"]["module_pads"]):
        x,z = float(pad["suggested_threshold_east_m"]),-float(pad["suggested_threshold_north_m"])
        y = float(pad["finished_floor_y_m"])
        patch_grid(grid,x-4.5,z-4.5,17.0,17.0,y-0.04,5.5)
        special.append([name,x,y,z,225])
        approach=[(x,z),(x+4.5,z+4.5),(x+8.2,z+8.2)]
        chunks[tile(x,z)]["routes"].append(["HV-ENTRY","walk",2.25,approach])
    grid.astype("<f4").tofile(DATA/"elevation.bin")
    for key,kind,width,points in roads+rail:
        detail = densify(points, 24)
        for n in range(0,len(detail)-1,2):
            section = detail[n:n+3]
            mid = section[len(section)//2]
            if any(math.dist(mid,p)<32 for p in bridges[key]):
                continue
            chunks[tile(*mid)]["routes"].append([key,kind,width,section])
    for a,b,ha,hb in zip(river,river[1:],river_heights,river_heights[1:]):
        chunks[tile((a[0]+b[0])/2,(a[1]+b[1])/2)]["routes"].append(["WESTFLOW","water",31,[a,b],[round(float(ha),3),round(float(hb),3)]])

    def place(key,x,z,angle=0,size=1):
        key = f"{key:04d}" if isinstance(key,int) else key
        if key not in catalog or max(abs(x),abs(z)) >= 4000:
            return
        bounds = catalog[key]["bounds"]
        half_x = (bounds[3]-bounds[0])*size/2
        half_z = (bounds[5]-bounds[2])*size/2
        for site,px,_,pz,yaw in special:
            if math.dist((x,z),(px,pz)) > 19+math.hypot(half_x,half_z):
                continue
            a = math.radians(yaw)
            lx = math.cos(a)*(x-px)-math.sin(a)*(z-pz)
            lz = math.sin(a)*(x-px)+math.cos(a)*(z-pz)
            delta = math.radians(angle-yaw)
            hx = abs(math.cos(delta))*half_x+abs(math.sin(delta))*half_z
            hz = abs(math.sin(delta))*half_x+abs(math.cos(delta))*half_z
            back = 14.5 if site == "apartment" else 8.0
            if abs(lx) < 2.8+hx and lz+hz > -6.9 and lz-hz < back:
                return
        chunks[tile(x,z)]["props"].append([key,round(x,2),round(z,2),angle,size])

    occupied = set()
    for key, items in LANDMARKS.items():
        x,z=world_point(poi[key]["xz_m"])
        for asset,dx,dz,angle in items:
            place(asset,x+dx,z+dz,angle)
            occupied.add(f"{asset:04d}" if isinstance(asset,int) else asset)

    x,z=world_point(poi["P06"]["xz_m"])
    for asset,dx,dz,angle in [("backpack",-2,4,30),("crate",-3,5,0),(164,2,0,45),(181,4,15,65),(198,-22,19,0),
                              (198,-30,40,10), (199,46,-47,0),(180,-6,-12,0),(24,2,-3,45)]:
        place(asset,x+dx,z+dz,angle)
        occupied.add(f"{asset:04d}" if isinstance(asset,int) else asset)
    for key, asset, dx, dz, angle in [
        ("P01","civic_flag",7,-25,0),("P03","arrivals_board",1,-18,0),
        ("P05","airport_hut",17,11,0),("P05","tape",9,18,0),
        ("P04","baggage_tug",-20,65,90),("P04","wheel_stop",-27,24,0),
        ("P07","stretcher",24,-28,90),("P11","stalled_bus",-11,-30,90),
        ("P12","cracked_glass",12,1,90),
    ]:
        px,pz=world_point(poi[key]["xz_m"])
        place(asset,px+dx,pz+dz,angle)
    for key, dx, dz, angle, size in [
        (82,29,13,45,.8),("apartment_block",44,-17,45,.61),(82,-34,-20,45,.74),
        (82,60,-46,45,.76),(82,-60,28,45,.73),
        (198,-14,27,0,.72),("alder",11,24,0,.80),(198,31,-10,20,.70),
        ("alder",37,-27,0,.78),(198,49,-40,0,.75),("alder",-26,-11,0,.70),
        (198,-51,19,0,.86),("alder",-58,39,0,.73),(198,-74,57,0,.70),
        (197,19,-7,30,1),(197,12,18,45,1),(181,21,-17,45,1),
        (180,25,-21,45,1),(180,46,-49,45,1),(180,-46,36,45,1),
        (200,-17,18,0,1),(200,20,-18,0,1),(196,-14,11,60,1),
    ]:
        place(key,x+dx,z+dz,angle,size)
    sx,sz=world_point(poi["P03"]["xz_m"])
    for i in (-3,-2,-1,1,2,3):
        place(112,sx+i*8.0,sz-12.0,0)
        if i % 2:
            place("station_glazing",sx+i*8.0,sz-11.0,0)

    # Reuse the authored scatter and evacuation spacing with the production meshes.
    with zipfile.ZipFile(groups[308][0]) as archive:
        scatter = read_json(archive,"Hillview_128_medium_Placements.json")
    for prop in scatter["placements"][::9]:
        key={"canvas_bag":"backpack","planter":197,"supply_crate":"crate","traffic_cone":195}.get(prop["type"])
        px,pz=prop["cell_x"]*128+prop["x"],prop["cell_z"]*128+prop["z"]
        if key is not None and math.dist((px,pz),p06) < 112:
            place(key,px,pz,math.degrees(prop["yaw_rad"]))
    with zipfile.ZipFile(groups[309][0]) as archive:
        jam = read_json(archive,"Jam_Profile.json")
    px,pz=world_point(poi["P05"]["xz_m"])
    pitch=jam["vehicle_families"][1]["length"]+jam["placement"]["gap_max"]
    for lane, delta in enumerate(jam["lane_offsets_x"]):
        for i in range(12):
            place((164,165,166,168,154)[(i+lane)%5],px+delta+10,pz+18+i*pitch+(lane*2),0)

    route_segments=[]
    for _,kind,width,points in roads+rail:
        for a,b in zip(points,points[1:]):
            route_segments.append((a,b,width/2+2.0))
    def away_from_routes(x,z,pad):
        for (ax,az),(bx,bz),radius in route_segments:
            if not (min(ax,bx)-radius-pad <= x <= max(ax,bx)+radius+pad and min(az,bz)-radius-pad <= z <= max(az,bz)+radius+pad):
                continue
            dx,dz=bx-ax,bz-az
            t=max(0,min(1,((x-ax)*dx+(z-az)*dz)/max(.01,dx*dx+dz*dz)))
            if math.hypot(x-ax-t*dx,z-az-t*dz) < radius+pad:
                return False
        return True

    adjusted = 0
    for f in footprints:
        x,z=world_point((float(f["x_m"]),float(f["z_m"])))
        w,d=float(f["width_m"]),float(f["depth_m"])
        origin = x,z
        def viable(px,pz):
            return (max(abs(px),abs(pz)) < 3960 and away_from_routes(px,pz,min(w,d)*.47)
                    and all(math.dist((px,pz),world_point(p["xz_m"])) > (90 if p["id"] in {"P04","P09"} else 52) for p in poi.values())
                    and not any(inside(px,pz,poly) for poly,_ in lakes))
        if not viable(x,z):
            positions=[(x+distance*math.cos(angle),z+distance*math.sin(angle)) for distance in (20,40,65,100,140)
                       for angle in (0,math.pi/2,math.pi,3*math.pi/2,.78,2.35,3.93,5.5)]
            x,z=next((p for p in positions if viable(*p)),(x,z))
        adjusted += (x,z) != origin
        use=f["use"]
        chunks[tile(x,z)]["buildings"].append([f["id"],round(x,2),round(z,2),w,d,int(f["floors_proposed"]),float(f["yaw_deg"]),use])

    # Detail the authored pilot street where the schematic footprint layer is sparse.
    for i, t in enumerate([-.39,-.30,-.20,-.10,.02,.14,.26,.37]):
        along=250*t
        for side in (-1,1):
            if side < 0 and i in (0,1,2,3):
                continue
            px=p06[0]+(along+side*43)*.707107
            pz=p06[1]+(-along+side*43)*.707107
            chunks[tile(px,pz)]["buildings"].append([f"HV-INFILL-{i}-{side}",px,pz,16.5,13.0,3+i%3,45,"residential"])

    # Place each model family in its relevant district, away from through lanes.
    homes={"01":"P13","02":"P11","03":"P03","04":"P01","05":"P15","06":"P06","07":"P16","08":"P07",
           "09":"P03","10":"P04","11":"P05","12":"P05","13":"P06","14":"P23","15":"P19","16":"P18",
           "17":"P09","18":"P24","19":"P05","20":"P01","21":"P06","22":"P06"}
    family_count=defaultdict(int)
    for key,data in intake.items():
        if key in occupied or key not in catalog or int(key) >= 323:
            continue
        group=data["category"]
        p=homes[group]
        x,z=world_point(poi[p]["xz_m"])
        k=family_count[group]
        family_count[group]+=1
        a=k*2.399963
        r=44+6*k
        xx,zz=x+math.cos(a)*r,z+math.sin(a)*r
        if not away_from_routes(xx,zz,4):
            xx,zz=x+math.cos(a)*(r+22),z+math.sin(a)*(r+22)
        place(key,xx,zz,round(math.degrees(a))%360)

    for district in districts.values():
        polygon=[world_point(p) for p in district["planning_boundary_xz_m"]]
        forest=district["land_use"] in ("nature","woodland")
        for _ in range(290 if forest else 95):
            x=RNG.uniform(min(p[0] for p in polygon),max(p[0] for p in polygon))
            z=RNG.uniform(min(p[1] for p in polygon),max(p[1] for p in polygon))
            if inside(x,z,polygon) and away_from_routes(x,z,10) and not any(inside(x,z,p) for p,_ in lakes):
                key=RNG.choice(["0199","fir"] if forest else ["0198","alder","0199"])
                chunks[tile(x,z)]["groves"].append([key,round(x,1),round(z,1),RNG.randrange(360),round(RNG.uniform(.65,1.1),2)])

    spawn=world_point(poi["P06"]["xz_m"])
    district_list=[[d["id"],d["name"],*world_point(d["anchor_xz_m"]),[world_point(p) for p in d["planning_boundary_xz_m"]]] for d in districts.values()]
    points=[[p["id"],p["name"],*world_point(p["xz_m"]),p["type"]] for p in poi.values()]
    with zipfile.ZipFile(groups[317][0]) as archive:
        shots=read_json(archive,"Camera_Shots.json")["shots"]
    with zipfile.ZipFile(groups[332][0]) as archive:
        vehicle=read_json(archive,"Socket_Contract.json")
    write_json(DATA/"city.json",{
        "grid":SIZE,"step":STEP,"tile":TILE,"chunks":chunks,"lakes":lakes,"points":points,"districts":district_list,
        "arterials":len(plan["arterials"]),"rail_lines":len(rail),"footprints":len(footprints),"footprints_shifted":adjusted,
        "missions":plan["mission_routes"],"special":special,"spawn":spawn,"paths":[[k,kind,w,p] for k,kind,w,p in roads+rail],
        "runway":runway,
        "bridge_count":sum(len(v) for v in bridges.values()),"camera_shots":shots,"vehicle":vehicle["fixture_body"],
    })
    print(f"Compiled {len(district_list)} districts, {len(points)} landmarks, {len(footprints)} footprints ({adjusted} site-fitted).",flush=True)


def main():
    DATA.mkdir(exist_ok=True)
    for directory in ("models","surfaces"):
        (CONTENT/directory).mkdir(parents=True,exist_ok=True)
    groups=discover()
    if "--layout-only" in sys.argv:
        catalog = json.loads((DATA / "catalog.json").read_text(encoding="utf-8"))
        intake = json.loads((DATA / "pack_index.json").read_text(encoding="utf-8"))
        if "--repair-jet" in sys.argv:
            model = copy_model(groups[136], "0136", PREFERRED.get(136), 512)
            catalog["0136"] = model
            intake["0136"]["representative"] = model
            intake["0136"]["runtime_repair"] = "Incomplete wing_lower_BaseColor PNG replaced with this aircraft's intact upper-wing finish"
        supplemental_assets(groups, catalog, intake)
        catalog["apartment"] = import_walkable_site(groups[67], "apartment", "Apartment_Walk_Test.tscn",
                                 {"Debug_Camera", "Sun", "COL_CapsuleTester", "WorldEnvironment", "UI", "Environment"})
        catalog["shop"] = import_walkable_site(groups[83], "shop", "Shop_Entry_Test.tscn",
                            {"Player", "Camera3D", "Sun", "WorldEnvironment", "UI", "Environment"})
        write_json(DATA / "catalog.json", catalog)
        write_json(DATA / "pack_index.json", intake)
    else:
        catalog,intake=asset_intake(groups)
    make_world(groups,catalog,intake)
    print(f"Imported {len(catalog)} model and site entries from {len(groups)} asset packs.",flush=True)


if __name__=="__main__":
    main()
