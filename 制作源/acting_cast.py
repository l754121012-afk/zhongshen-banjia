"""Rebuild the articulated dialogue body from the original courier sculpture."""
from pathlib import Path
import bpy

source_dir = Path(__file__).resolve().parent
helpers = (source_dir / "sculpt.py").read_text(encoding="utf8")
exec(helpers[:helpers.index("def export(")].replace("m.node_tree.nodes.get('Principled BSDF')", "next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')"))
source = (source_dir / "courier.py").read_text(encoding="utf8")
exec(source[source.index("clear()\nskin="):source.index("export('courier_body')")])

def pivot(name, position, parent=None):
    node = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(node)
    node.location = conv(position)
    bpy.context.view_layer.update()
    if parent:
        attach(node, parent)
    return node

def attach(node, parent):
    world = node.matrix_world.copy()
    node.parent = parent
    node.matrix_world = world

head = pivot("Gaze", (0, 1.27, 0))
eyes = pivot("Lids", (0, 1.57, .315), head)
smile = pivot("Smile", (0, 1.388, .313), head)
mouth = pivot("Speech", (0, 1.389, .318), head)
gaze = pivot("Pupils", (0, 1.57, .342), eyes)
brows = [pivot("BrowL" if i == -1 else "BrowR",
               (i * .15, 1.667, .32), head) for i in [-1, 1]]
open_mouth = orb("openmouth", (0, 1.39, .316), (.166, .082, .044), "784C43")
skip = {"tunic","belt","buckle","lapel","button","strap","satchel","satchel flap","neck"}
groups = {}
for obj in list(bpy.context.scene.objects):
    if obj.type not in ('CURVE', 'MESH'):
        continue
    key = obj.name.split('.')[0]
    if key == 'openmouth': owner = mouth
    elif key == 'grin': owner = smile
    elif key in ('eye white',): owner = eyes
    elif key in ('eye','glint'): owner = gaze
    elif key == 'brow':
        point = obj.data.splines[0].bezier_points[0].co
        owner = brows[0 if point.x < 0 else 1]
    elif key not in skip or (key=='button' and obj.location.z>1.5): owner = head
    else: owner = None
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    if obj.type=='CURVE' or len(obj.modifiers):
        bpy.ops.object.convert(target='MESH')
    groups.setdefault((owner,obj.data.materials[0].name), []).append(obj)

# Keep the familiar material names on the clothing for the existing costume painter.
for (owner, color), objects in groups.items():
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects: obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    if len(objects)>1: bpy.ops.object.join()
    obj=bpy.context.view_layer.objects.active
    obj.name=("body" if owner is None else ("head" if owner==head else owner.name))+"_"+color
    if owner: attach(obj,owner)
bpy.ops.export_scene.gltf(filepath=str(out/"courier_acting.glb"),export_format="GLB",
                          export_yup=True,export_cameras=False,export_lights=False)

