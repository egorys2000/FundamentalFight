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

    def fine_box(self, x0, y0, z0, width, height, depth, material):
        for x in range(x0, x0 + width):
            for y in range(y0, y0 + height):
                for z in range(z0, z0 + depth):
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
        component_bounds = []
        while unseen:
            components += 1
            first = unseen.pop()
            stack = [first]
            members = [first]
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
                        members.append(neighbor)
            component_bounds.append((
                min(item[0] for item in members), max(item[0] for item in members),
                min(item[1] for item in members), max(item[1] for item in members),
                min(item[2] for item in members), max(item[2] for item in members),
            ))
        if components > 1:
            raise ValueError("%s has %d disconnected voxel islands: %s" % (self.name, components, component_bounds))
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


def make_ground(name, ground, edge):
    model = VoxelModel(name)
    model.box(-4, 0, -4, 8, 1, 8, edge)
    model.box(-3, 1, -3, 6, 1, 6, ground)
    return model.create()


def make_crag(name, stone, shadow, highlight, unbreakable=False, variant=0):
    model = VoxelModel(name)
    # Primary form: a broad, asymmetric mountain mass with a heavy base and
    # a deliberate split summit. Layer widths change in long geological
    # rhythms rather than repeating identical centered boxes.
    strata = [
        (0, 11, 25, 21, -2, 1),
        (11, 17, 22, 18, -1, 1),
        (17, 28, 19, 16, 1, 0),
        (28, 35, 16, 14, 2, -1),
        (35, 47, 13, 12, 3, -1),
        (47, 53, 10, 10, 2, 0),
        (53, 63, 7, 8, 0, 1),
        (63, 69, 4, 5, -2, 1),
    ]
    if variant == 1:
        strata = [(y, h, max(3, rx + 2), max(3, rz - 2), ox + (y // 10), oz) for y, h, rx, rz, ox, oz in strata]
    for index, band in enumerate(strata):
        y0, y1, rx, rz, ox, oz = band
        for y in range(y0, y1):
            inset = max(0, (y - y0) // 4)
            local_rx = max(3, rx - inset)
            local_rz = max(3, rz - inset)
            for x in range(ox - local_rx, ox + local_rx + 1):
                for z in range(oz - local_rz, oz + local_rz + 1):
                    contour = (abs(x - ox) / local_rx) ** 1.7 + (abs(z - oz) / local_rz) ** 1.7
                    if contour <= 1.0:
                        mat = shadow if index == 0 and y < 3 else stone
                        if y == y0 and index > 0 and contour > 0.80:
                            mat = highlight
                        model.set(x, y, z, mat)
    # Secondary forms: structural buttresses explain the mountain's mass and
    # create strong foreground silhouette events.
    model.fine_box(-22, 5, -4, 7, 25, 7, shadow)
    model.fine_box(15, 8, 5, 6, 21, 6, shadow)
    if variant == 1:
        model.fine_box(-14, 15, 8, 5, 26, 5, stone)
        model.fine_box(9, 28, -10, 5, 23, 5, stone)
    else:
        model.fine_box(-11, 18, 10, 5, 19, 5, stone)
        model.fine_box(7, 34, -8, 5, 17, 5, stone)
    # A stepped summit ridge and a narrow saddle make the peak feel geological
    # instead of like a tower assembled from equal cubes.
    model.fine_box(-7, 63, -3, 13, 3, 7, highlight)
    model.fine_box(-4, 66, -2, 8, 3, 5, stone)
    model.fine_box(0, 69, -1, 4, 2, 3, highlight)
    # Tertiary focal detail: two dark fissure mouths and sparse strata chips.
    model.fine_box(-2, 25, -10, 4, 8, 2, shadow)
    model.fine_box(6, 42, 6, 3, 7, 2, shadow)
    for x, y, z in [(-8, 13, -4), (8, 25, 2), (-4, 40, 3), (3, 53, -2), (-2, 60, 2)]:
        model.fine_box(x, y, z, 3, 2, 2, highlight)
    if unbreakable:
        # The luminous seam is embedded in the mass, not pasted on its surface.
        for y in range(17, 61):
            x = -5 if y < 39 else 3
            model.fine_box(x, y, 0, 2, 2, 2, highlight)
    return model.create()


def make_cactus(cactus, light, flower, variant=0):
    model = VoxelModel("CactusVariant%d" % variant)
    model.box(-1, 0, -1, 3, 1, 3, cactus)
    trunk_height = 7 if variant != 2 else 5
    model.box(-1, 1, -1, 3, trunk_height, 3, cactus)
    if variant == 0:
        model.box(-4, 3, -1, 3, 2, 3, light)
        model.box(-4, 4, -1, 2, 3, 3, cactus)
        model.box(2, 5, -1, 3, 2, 3, light)
        model.box(4, 5, -1, 2, 3, 3, cactus)
    elif variant == 1:
        model.box(-4, 2, -1, 3, 2, 3, light)
        model.box(-4, 2, -1, 2, 4, 3, cactus)
        model.box(2, 4, -1, 3, 2, 3, light)
        model.box(4, 4, -1, 2, 4, 3, cactus)
        model.box(1, 7, -1, 2, 2, 3, light)
    else:
        model.box(-4, 2, -1, 3, 2, 3, light)
        model.box(-4, 2, -1, 2, 3, 3, cactus)
        model.box(2, 3, -1, 3, 2, 3, light)
        model.box(4, 3, -1, 2, 3, 3, cactus)
    model.box(-1, trunk_height + 1, -1, 3, 1, 3, flower)
    return model.create()


def make_player(player, visor, beacon, shadow):
    model = VoxelModel("Player")
    # Primary form: tall field cartographer with a long coat and broad hat.
    model.box(-2, 0, -2, 4, 1, 4, shadow)
    model.box(-2, 1, -1, 4, 2, 3, shadow)
    model.box(-2, 3, -1, 4, 7, 3, player)
    model.box(-3, 4, -1, 1, 5, 3, player)
    model.box(2, 4, -1, 1, 5, 3, player)
    # Secondary construction: coat opening, belt, shoulder satchel, and boots.
    model.fine_box(-2, 20, -1, 4, 6, 3, player)
    model.fine_box(-1, 6, -2, 2, 5, 1, shadow)
    model.fine_box(-3, 8, 0, 2, 2, 3, shadow)
    model.fine_box(2, 6, -1, 2, 3, 2, shadow)
    model.fine_box(-2, 2, -2, 1, 2, 2, player)
    model.fine_box(1, 2, -2, 1, 2, 2, player)
    # Face and hat are the recognition focal area.
    model.fine_box(-2, 22, -2, 4, 2, 1, visor)
    model.box(-4, 13, -3, 8, 1, 7, player)
    model.fine_box(-6, 28, -4, 12, 4, 8, player)
    model.fine_box(-4, 32, -2, 8, 2, 4, shadow)
    model.fine_box(-2, 34, 0, 4, 4, 4, beacon)
    # A single asymmetric field tool gives the silhouette a functional story.
    model.fine_box(3, 7, -1, 3, 2, 2, shadow)
    model.fine_box(5, 5, -1, 2, 2, 2, beacon)
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
    positions = [(-12.0, -9.0, 0.0), (0.0, -9.0, 0.0), (12.0, -9.0, 0.0),
                 (-12.0, 0.0, 0.0), (0.0, 0.0, 0.0), (12.0, 0.0, 0.0),
                 (-12.0, 9.0, 0.0), (0.0, 9.0, 0.0), (12.0, 9.0, 0.0)]
    for root, position in zip(roots, positions):
        root.location = position
    plinth = VoxelModel("PreviewPlinth")
    plinth.box(-42, -1, -30, 84, 1, 60, edge)
    plinth.box(-41, 0, -29, 82, 1, 58, ground)
    plinth.create()
    camera_data = bpy.data.cameras.new("Preview Camera")
    camera = bpy.data.objects.new("Preview Camera", camera_data)
    bpy.context.collection.objects.link(camera)
    # Look from logical negative-Z so the hero's face/visor is readable.
    camera.location = (22.0, -28.0, 24.0)
    camera.rotation_euler = (Vector((0.0, 0.0, 3.0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 34.0
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
    (ground_mat, "ground"), (ground_edge_mat, "ground_edge"),
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
    ("crag_breakable.glb", make_crag("CragBreakable", breakable_mat, breakable_dark_mat, breakable_mat)),
    ("crag_unbreakable.glb", make_crag("CragUnbreakable", unbreakable_mat, breakable_dark_mat, unbreakable_highlight_mat, True)),
    ("crag_breakable_spire.glb", make_crag("CragBreakableSpire", breakable_mat, breakable_dark_mat, breakable_mat, False, 1)),
    ("crag_unbreakable_spire.glb", make_crag("CragUnbreakableSpire", unbreakable_mat, breakable_dark_mat, unbreakable_highlight_mat, True, 1)),
    ("cactus.glb", make_cactus(cactus_mat, cactus_light_mat, flower_mat, 0)),
    ("cactus_twin.glb", make_cactus(cactus_mat, cactus_light_mat, flower_mat, 1)),
    ("cactus_low.glb", make_cactus(cactus_mat, cactus_light_mat, flower_mat, 2)),
    ("player_placeholder.glb", make_player(player_mat, visor_mat, flower_mat, ground_edge_mat)),
]
for filename, root in assets:
    export_asset(filename, root)
    print("  cells:", len(root.children[0].data.vertices) // 4, "surface quads")

make_preview([root for _, root in assets], ground_edge_mat, ground_mat)
print("Voxel asset generation complete:", len(assets), "assets at", VOXEL_SIZE, "m/cell")
