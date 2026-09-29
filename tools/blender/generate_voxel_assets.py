"""Grid-authored voxel asset generator for Fundamental Fight.

Every model is an occupancy map of integer cells.  The mesher only emits
faces on the boundary of occupied cells, so all geometry remains on the
voxel lattice.  This is deliberately small and data-oriented: adding an
asset means adding cells, not positioning arbitrary primitives.

Run:
    blender -b --python tools/blender/generate_voxel_assets.py
"""

import math
import os

import bpy
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUTPUT = os.path.join(ROOT, "assets", "generated")
VOXEL_SIZE = 0.125
AUTHORED_CELL = 0.25
RESOLUTION_SCALE = int(round(AUTHORED_CELL / VOXEL_SIZE))

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


def material(name, color=(0.8, 0.8, 0.8, 1.0), emission=False):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Roughness"].default_value = 0.86
    if emission:
        principled.inputs["Emission Color"].default_value = color
        principled.inputs["Emission Strength"].default_value = 0.7
    return mat


class VoxelModel:
    """Integer voxel model with logical Y-up coordinates.

    Asset coordinates are written as (x, y, z), where y is height. Blender is
    Z-up, so the mesh conversion below maps logical (x, y, z) to Blender
    (x, z, y). The exported glTF then presents the asset upright to Godot.
    """

    def __init__(self, name):
        self.name = name
        self.cells = {}

    def set(self, x, y, z, material):
        self.cells[(int(x), int(y), int(z))] = material
        return self

    def box(self, x0, y0, z0, width, height, depth, material):
        scale = RESOLUTION_SCALE
        for x in range(x0 * scale, (x0 + width) * scale):
            for y in range(y0 * scale, (y0 + height) * scale):
                for z in range(z0 * scale, (z0 + depth) * scale):
                    self.set(x, y, z, material)
        return self

    def validate(self):
        if not self.cells:
            raise ValueError("%s has no occupied cells" % self.name)
        for coordinate, mat in self.cells.items():
            if not all(isinstance(value, int) for value in coordinate):
                raise ValueError("%s contains a non-integer cell" % self.name)
            if mat is None:
                raise ValueError("%s contains an unpainted cell at %s" % (self.name, coordinate))
        unseen = set(self.cells)
        components = 0
        while unseen:
            components += 1
            stack = [unseen.pop()]
            while stack:
                x, y, z = stack.pop()
                for neighbor in (
                    (x + 1, y, z), (x - 1, y, z),
                    (x, y + 1, z), (x, y - 1, z),
                    (x, y, z + 1), (x, y, z - 1),
                ):
                    if neighbor in unseen:
                        unseen.remove(neighbor)
                        stack.append(neighbor)
        if components > 1:
            raise ValueError("%s has %d disconnected voxel islands" % (self.name, components))
        palette = set(self.cells.values())
        if len(palette) > 6:
            raise ValueError("%s uses %d materials; keep the asset palette intentional" % (self.name, len(palette)))
        return self

    def mesh(self):
        self.validate()
        vertices = []
        faces = []
        face_materials = []
        directions = [
            ((1, 0, 0), ((1, 0, 0), (1, 0, 1), (1, 1, 1), (1, 1, 0))),
            ((-1, 0, 0), ((0, 0, 0), (0, 1, 0), (0, 1, 1), (0, 0, 1))),
            ((0, 1, 0), ((0, 1, 0), (1, 1, 0), (1, 1, 1), (0, 1, 1))),
            ((0, -1, 0), ((0, 0, 0), (0, 0, 1), (1, 0, 1), (1, 0, 0))),
            ((0, 0, 1), ((0, 0, 1), (0, 1, 1), (1, 1, 1), (1, 0, 1))),
            ((0, 0, -1), ((0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0))),
        ]
        for (x, y, z), mat in self.cells.items():
            for direction, corners in directions:
                neighbor = (x + direction[0], y + direction[1], z + direction[2])
                if neighbor in self.cells:
                    continue
                start = len(vertices)
                vertices.extend([
                    ((x + corner[0]) * VOXEL_SIZE,
                     (z + corner[2]) * VOXEL_SIZE,
                     (y + corner[1]) * VOXEL_SIZE)
                    for corner in corners
                ])
                faces.append((start, start + 1, start + 2, start + 3))
                face_materials.append(mat)
        mesh = bpy.data.meshes.new(self.name + "Mesh")
        mesh.from_pydata(vertices, [], faces)
        mesh.materials.clear()
        ordered_materials = []
        for mat in face_materials:
            if mat not in ordered_materials:
                ordered_materials.append(mat)
                mesh.materials.append(mat)
        for polygon, mat in zip(mesh.polygons, face_materials):
            polygon.material_index = ordered_materials.index(mat)
            polygon.use_smooth = False
        mesh.update()
        return mesh

    def create(self):
        self.validate()
        root = bpy.data.objects.new(self.name, None)
        bpy.context.collection.objects.link(root)
        obj = bpy.data.objects.new(self.name + "Surface", self.mesh())
        bpy.context.collection.objects.link(obj)
        obj.parent = root
        return root


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def export_asset(filename, root):
    # Keep the exported convention explicit: Godot and glTF both use Y-up.
    root.rotation_euler = (0.0, 0.0, 0.0)
    root.scale = (1.0, 1.0, 1.0)
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for child in root.children_recursive:
        child.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUTPUT, filename),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
    )
    print("Generated", os.path.join(OUTPUT, filename))


def make_ground(name, ground, edge, grass=None):
    model = VoxelModel(name)
    model.box(-4, 0, -4, 8, 1, 8, edge)
    model.box(-3, 1, -3, 6, 1, 6, ground)
    if grass:
        for x, z in [(-2, -1), (1, 2), (2, -2), (-1, 2)]:
            model.box(x, 2, z, 1, 1, 1, grass)
    return model.create()


def make_crag(name, stone, shadow, highlight, unbreakable=False):
    model = VoxelModel(name)
    # Monumental anchors: the playable loop should read as permanently
    # committed around a landmark, not like a small pebble.
    # A mountain is designed as changing horizontal strata, not stacked cubes.
    # Each layer has a different footprint and offset, producing ridges,
    # shelves, gullies, and a readable taper at the finer voxel resolution.
    for y in range(0, 68):
        t = y / 67.0
        radius_x = max(3, int(round(24.0 * (1.0 - t ** 0.72))))
        radius_z = max(3, int(round(20.0 * (1.0 - t ** 0.82))))
        offset_x = int(round(math.sin(y * 0.37) * max(0, radius_x - 4)))
        offset_z = int(round(math.cos(y * 0.23) * max(0, radius_z - 4)))
        layer_material = shadow if y < 8 else stone
        for x in range(-radius_x + offset_x, radius_x + offset_x + 1):
            for z in range(-radius_z + offset_z, radius_z + offset_z + 1):
                edge = abs(x - offset_x) / max(1, radius_x) + abs(z - offset_z) / max(1, radius_z)
                if edge < 1.45 or (y < 16 and edge < 1.8):
                    mat = layer_material
                    if y in (8, 18, 30, 43, 55) and edge > 1.1:
                        mat = highlight
                    model.set(x, y, z, mat)
    # A continuous inner spine makes every terrace a believable part of one
    # mountain even when the outer contour steps inward sharply.
    model.box(-4, 0, -4, 8, 34, 8, shadow)
    # Recesses are represented by material bands and offset terraces rather
    # than carving through the load-bearing core; the mountain stays one mass.
    if unbreakable:
        for y in range(18, 58):
            x = -3 if y < 36 else 2
            model.set(x, y, 0, highlight)
    return model.create()


def make_cactus(cactus, light, flower):
    model = VoxelModel("Cactus")
    model.box(-1, 0, -1, 3, 1, 3, cactus)
    model.box(-1, 1, -1, 3, 6, 3, cactus)
    model.box(-4, 3, -1, 3, 2, 3, light)
    model.box(-4, 4, -1, 2, 3, 3, cactus)
    model.box(2, 5, -1, 3, 2, 3, light)
    model.box(4, 5, -1, 2, 3, 3, cactus)
    model.box(-1, 7, -1, 3, 1, 3, flower)
    return model.create()


def make_player(player, visor, beacon, shadow):
    model = VoxelModel("Player")
    # A tall traveler silhouette: boots, long coat, face, broad hat and
    # antenna-like crown. The brim is the recognition cue at bird-view scale.
    model.box(-2, 0, -2, 4, 1, 4, shadow)
    model.box(-2, 1, -1, 4, 2, 3, shadow)
    model.box(-2, 3, -1, 4, 7, 3, player)
    model.box(-3, 4, -1, 1, 5, 3, player)
    model.box(2, 4, -1, 1, 5, 3, player)
    model.box(-2, 10, -1, 4, 3, 3, player)
    model.box(-2, 11, -2, 4, 2, 1, visor)
    model.box(-4, 13, -3, 8, 1, 7, player)
    model.box(-3, 14, -2, 6, 2, 5, player)
    model.box(-2, 16, -1, 4, 1, 3, player)
    model.box(-1, 17, 0, 2, 2, 2, beacon)
    return model.create()


def configure_scene():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.world.color = (0.025, 0.04, 0.05)
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0


def make_preview(roots, edge, ground):
    positions = [(-7.0, 1.8, 0.0), (-2.0, 1.8, 0.0), (-5.0, -2.5, 0.0),
                 (0.0, -2.5, 0.0), (5.2, 0.8, 0.0), (4.0, -3.0, 0.0)]
    for root, position in zip(roots, positions):
        root.location = position
    plinth = VoxelModel("PreviewPlinth")
    plinth.box(-36, -1, -22, 72, 1, 44, edge)
    plinth.box(-35, 0, -21, 70, 1, 42, ground)
    plinth.create()
    camera_data = bpy.data.cameras.new("Preview Camera")
    camera = bpy.data.objects.new("Preview Camera", camera_data)
    bpy.context.collection.objects.link(camera)
    # Look from logical negative-Z so the hero's face/visor is readable.
    camera.location = (14.0, -18.0, 15.0)
    camera.rotation_euler = (Vector((0.0, 0.0, 3.0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 22.0
    bpy.context.scene.camera = camera
    for location, energy, color, size in [
        ((-4.0, 8.0, 5.0), 1000.0, (1.0, 0.72, 0.46), 5.0),
        ((4.0, 5.0, -3.0), 700.0, (0.30, 0.55, 1.0), 4.0),
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
    sun_data = bpy.data.lights.new("Mountain preview sun", "SUN")
    sun_data.energy = 2.5
    sun_data.angle = math.radians(20.0)
    sun = bpy.data.objects.new("Mountain preview sun", sun_data)
    bpy.context.collection.objects.link(sun)
    sun.rotation_euler = (Vector((0.0, 0.0, 2.0)) - Vector((-8.0, -10.0, 14.0))).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.render.filepath = os.path.join(OUTPUT, "voxel_kit_preview.png")
    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)


reset_scene()
configure_scene()
os.makedirs(OUTPUT, exist_ok=True)

ground_mat = material("Ground")
ground_edge_mat = material("Ground Edge")
grass_mat = material("Grass")
breakable_mat = material("Breakable Stone")
breakable_dark_mat = material("Breakable Stone Shadow")
unbreakable_mat = material("Unbreakable Stone")
unbreakable_highlight_mat = material("Unbreakable Rune", emission=True)
cactus_mat = material("Cactus")
cactus_light_mat = material("Cactus Light")
flower_mat = material("Flower", emission=True)
player_mat = material("Player")
visor_mat = material("Visor", emission=True)
for mat, key in [
    (ground_mat, "ground"), (ground_edge_mat, "ground_edge"), (grass_mat, "grass"),
    (breakable_mat, "breakable"), (breakable_dark_mat, "breakable_dark"),
    (unbreakable_mat, "unbreakable"), (unbreakable_highlight_mat, "unbreakable_highlight"),
    (cactus_mat, "cactus"), (cactus_light_mat, "cactus_light"), (flower_mat, "flower"),
    (player_mat, "player"), (visor_mat, "visor"),
]:
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = COLORS[key]
    mat.diffuse_color = COLORS[key]

assets = [
    ("ground_tile.glb", make_ground("GroundTile", ground_mat, ground_edge_mat)),
    ("ground_tile_grass.glb", make_ground("GroundTileGrass", ground_mat, ground_edge_mat, grass_mat)),
    ("crag_breakable.glb", make_crag("CragBreakable", breakable_mat, breakable_dark_mat, breakable_mat)),
    ("crag_unbreakable.glb", make_crag("CragUnbreakable", unbreakable_mat, breakable_dark_mat, unbreakable_highlight_mat, True)),
    ("cactus.glb", make_cactus(cactus_mat, cactus_light_mat, flower_mat)),
    ("player_placeholder.glb", make_player(player_mat, visor_mat, flower_mat, ground_edge_mat)),
]
for filename, root in assets:
    export_asset(filename, root)
    print("  cells:", len(root.children[0].data.vertices) // 4, "surface quads")

make_preview([root for _, root in assets], ground_edge_mat, ground_mat)
print("Voxel asset generation complete:", len(assets), "assets at", VOXEL_SIZE, "m/cell")
