"""Generate the first voxel art kit for Fundamental Fight.

Run with:
    blender -b --python tools/blender/generate_voxel_assets.py

The generator intentionally uses only primitive meshes so the assets can be
regenerated and replaced without hand-authored Blender state.
"""

import math
import os
import sys

import bpy
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUTPUT = os.path.join(ROOT, "assets", "generated")

COLORS = {
    "ground": (0.16, 0.25, 0.28, 1.0),
    "ground_edge": (0.30, 0.45, 0.46, 1.0),
    "grass": (0.25, 0.48, 0.34, 1.0),
    "breakable": (0.34, 0.46, 0.47, 1.0),
    "breakable_dark": (0.20, 0.29, 0.32, 1.0),
    "unbreakable": (0.24, 0.20, 0.31, 1.0),
    "unbreakable_highlight": (0.49, 0.32, 0.60, 1.0),
    "cactus": (0.22, 0.55, 0.38, 1.0),
    "cactus_light": (0.42, 0.72, 0.42, 1.0),
    "flower": (0.91, 0.46, 0.30, 1.0),
    "player": (0.89, 0.60, 0.25, 1.0),
    "visor": (0.29, 0.72, 0.75, 1.0),
}


def material(name, color, roughness=0.82, emission=None):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Roughness"].default_value = roughness
    if emission:
        principled.inputs["Emission Color"].default_value = emission
        principled.inputs["Emission Strength"].default_value = 0.7
    return mat


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def apply_material(obj, mat):
    obj.data.materials.append(mat)
    if hasattr(obj.data, "polygons"):
        for polygon in obj.data.polygons:
            polygon.use_smooth = False


def cube(name, location, scale, mat, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] / 2.0, scale[1] / 2.0, scale[2] / 2.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    apply_material(obj, mat)
    if bevel:
        modifier = obj.modifiers.new("Soft voxel edge", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj


def cylinder(name, location, radius, depth, mat, vertices=8, rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=location,
        rotation=rotation or (0.0, 0.0, 0.0),
    )
    obj = bpy.context.object
    obj.name = name
    apply_material(obj, mat)
    return obj


def export_asset(filename, root):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for child in root.children_recursive:
        child.select_set(True)
    bpy.context.view_layer.objects.active = root
    path = os.path.join(OUTPUT, filename)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
    )
    print("Generated", path)


def make_ground(name, top_mat, edge_mat, accent=False):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    base = cube("Ground tile", (0.0, 0.16, 0.0), (2.0, 0.32, 2.0), edge_mat, 0.05)
    base.parent = root
    top = cube("Ground surface", (0.0, 0.36, 0.0), (1.84, 0.12, 1.84), top_mat, 0.025)
    top.parent = root
    if accent:
        for x, z in ((-0.55, -0.35), (0.35, 0.45), (0.55, -0.55)):
            tuft = cube("Grass accent", (x, 0.45, z), (0.12, 0.05, 0.12), grass_mat, 0.01)
            tuft.parent = root
    return root


def make_crag(name, body_mat, shadow_mat, highlight_mat, unbreakable=False):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    base = cube("Crag foot", (0.0, 0.30, 0.0), (1.18, 0.42, 1.18), shadow_mat, 0.06)
    base.parent = root
    shards = [
        (-0.30, 0.66, 0.08, 0.48, 0.66, 0.44, -8.0),
        (0.20, 0.76, -0.06, 0.42, 0.88, 0.42, 7.0),
        (-0.02, 1.10, 0.02, 0.33, 0.70, 0.34, -5.0),
        (0.22, 1.36, -0.02, 0.24, 0.46, 0.25, 8.0),
    ]
    for i, (x, y, z, sx, sy, sz, angle) in enumerate(shards):
        shard = cube("Crag voxel shard %d" % i, (x, y, z), (sx, sy, sz), body_mat, 0.025)
        shard.rotation_euler[1] = math.radians(angle)
        shard.parent = root
    for i, (x, y, z, sx, sy, sz) in enumerate([
        (-0.52, 0.54, 0.24, 0.18, 0.22, 0.26),
        (0.50, 0.48, -0.20, 0.22, 0.18, 0.20),
        (-0.16, 1.42, 0.08, 0.18, 0.16, 0.18),
    ]):
        chip = cube("Crag chip %d" % i, (x, y, z), (sx, sy, sz), highlight_mat, 0.012)
        chip.parent = root
    if unbreakable:
        for side in (-1, 1):
            rune = cube("Unbreakable rune", (side * 0.40, 0.78, -0.30), (0.16, 0.30, 0.06), highlight_mat, 0.01)
            rune.parent = root
    return root


def make_cactus():
    root = bpy.data.objects.new("Cactus", None)
    bpy.context.collection.objects.link(root)
    trunk = cube("Cactus trunk", (0.0, 0.78, 0.0), (0.42, 1.45, 0.42), cactus_mat, 0.06)
    trunk.parent = root
    left = cube("Cactus arm left", (-0.30, 0.84, 0.0), (0.64, 0.30, 0.30), cactus_light_mat, 0.045)
    left.parent = root
    left_cap = cube("Cactus arm tip left", (-0.60, 1.05, 0.0), (0.30, 0.62, 0.30), cactus_mat, 0.045)
    left_cap.parent = root
    right = cube("Cactus arm right", (0.25, 1.05, 0.0), (0.54, 0.30, 0.30), cactus_light_mat, 0.045)
    right.parent = root
    right_cap = cube("Cactus arm tip right", (0.52, 1.24, 0.0), (0.30, 0.52, 0.30), cactus_mat, 0.045)
    right_cap.parent = root
    flower = cube("Cactus flower", (0.0, 1.57, 0.0), (0.28, 0.14, 0.28), flower_mat, 0.025)
    flower.parent = root
    for x, y in [(-0.13, 0.52), (0.14, 0.96), (-0.12, 1.22), (0.12, 1.42)]:
        spine = cube("Cactus spine", (x, y, -0.22), (0.035, 0.09, 0.05), flower_mat, 0.005)
        spine.parent = root
    return root


def make_player():
    root = bpy.data.objects.new("Player", None)
    bpy.context.collection.objects.link(root)
    shadow = cube("Player shadow", (0.0, 0.08, 0.0), (0.78, 0.10, 0.58), ground_edge_mat, 0.04)
    shadow.parent = root
    body = cube("Player body", (0.0, 0.68, 0.0), (0.58, 0.90, 0.48), player_mat, 0.07)
    body.parent = root
    head = cube("Player helmet", (0.0, 1.25, 0.0), (0.66, 0.38, 0.62), player_mat, 0.05)
    head.parent = root
    visor = cube("Player visor", (0.0, 1.28, -0.33), (0.44, 0.14, 0.08), visor_mat, 0.015)
    visor.parent = root
    antenna = cube("Player antenna", (0.0, 1.58, 0.0), (0.08, 0.28, 0.08), visor_mat, 0.015)
    antenna.parent = root
    beacon = cube("Player beacon", (0.0, 1.74, 0.0), (0.12, 0.12, 0.12), flower_mat, 0.01)
    beacon.parent = root
    return root


def configure_scene():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.world.color = (0.025, 0.04, 0.05)
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0


def make_preview(roots):
    """Render a small style check showing the kit as a diorama, not a flat catalog."""
    for root in roots:
        root.location = (0.0, 0.0, 0.0)
    roots[0].location = (-2.2, 0.0, 1.4)
    roots[1].location = (0.0, 0.0, 1.4)
    roots[2].location = (-1.6, 0.0, -0.8)
    roots[3].location = (0.0, 0.0, -0.8)
    roots[4].location = (1.7, 0.0, 0.3)
    roots[5].location = (1.0, 0.0, -1.4)
    preview_ground = cube("Preview plinth", (0.0, -0.12, 0.0), (6.6, 0.25, 5.0), ground_edge_mat, 0.12)
    preview_top = cube("Preview grass top", (0.0, 0.03, 0.0), (6.35, 0.10, 4.75), ground_mat, 0.05)
    camera_data = bpy.data.cameras.new("Preview Camera")
    camera = bpy.data.objects.new("Preview Camera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = (7.2, 8.0, 8.5)
    camera.rotation_euler = (Vector((0.0, 0.5, 0.0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 7.4
    bpy.context.scene.camera = camera
    for location, energy, color, size in [
        ((-4.0, 7.0, 4.0), 1000.0, (1.0, 0.72, 0.46), 5.0),
        ((4.0, 4.0, -3.0), 700.0, (0.30, 0.55, 1.0), 4.0),
    ]:
        light_data = bpy.data.lights.new("Preview light", "AREA")
        light_data.energy = energy
        light_data.color = color
        light_data.shape = "DISK"
        light_data.size = size
        light = bpy.data.objects.new("Preview light", light_data)
        bpy.context.collection.objects.link(light)
        light.location = location
        light.rotation_euler = (Vector((0.0, 0.0, 0.0)) - light.location).to_track_quat("-Z", "Y").to_euler()
    sun_data = bpy.data.lights.new("Preview sun", "SUN")
    sun_data.energy = 2.0
    sun_data.angle = math.radians(18.0)
    sun = bpy.data.objects.new("Preview sun", sun_data)
    bpy.context.collection.objects.link(sun)
    sun.rotation_euler = (Vector((0.0, 0.0, 0.0)) - Vector((-4.0, 7.0, 4.0))).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.render.filepath = os.path.join(OUTPUT, "voxel_kit_preview.png")
    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)


reset_scene()
configure_scene()
os.makedirs(OUTPUT, exist_ok=True)

ground_mat = material("Ground teal", COLORS["ground"])
ground_edge_mat = material("Ground edge", COLORS["ground_edge"])
grass_mat = material("Grass accent", COLORS["grass"])
breakable_mat = material("Breakable stone", COLORS["breakable"])
breakable_dark_mat = material("Breakable stone shadow", COLORS["breakable_dark"])
unbreakable_mat = material("Unbreakable violet stone", COLORS["unbreakable"])
unbreakable_highlight_mat = material("Unbreakable rune", COLORS["unbreakable_highlight"], emission=COLORS["unbreakable_highlight"])
cactus_mat = material("Cactus green", COLORS["cactus"])
cactus_light_mat = material("Cactus light", COLORS["cactus_light"])
flower_mat = material("Warm orange flower", COLORS["flower"], emission=COLORS["flower"])
player_mat = material("Player gold", COLORS["player"])
visor_mat = material("Player cyan visor", COLORS["visor"], emission=COLORS["visor"])

assets = [
    ("ground_tile.glb", make_ground("GroundTile", ground_mat, ground_edge_mat)),
    ("ground_tile_grass.glb", make_ground("GroundTileGrass", ground_mat, ground_edge_mat, True)),
    ("crag_breakable.glb", make_crag("CragBreakable", breakable_mat, breakable_dark_mat, breakable_mat)),
    ("crag_unbreakable.glb", make_crag("CragUnbreakable", unbreakable_mat, breakable_dark_mat, unbreakable_highlight_mat, True)),
    ("cactus.glb", make_cactus()),
    ("player_placeholder.glb", make_player()),
]

for filename, root in assets:
    export_asset(filename, root)
    bpy.ops.object.select_all(action="DESELECT")

make_preview([root for _, root in assets])
print("Voxel asset generation complete:", len(assets), "assets")
