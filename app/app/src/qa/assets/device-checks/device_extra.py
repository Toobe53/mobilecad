"""Extra on-device cache checks: sketches and undo/redo (see device_check.py)."""
from mobilecad import bridge
import FreeCAD as App
import json
import Part

out = []
doc = App.ActiveDocument or App.newDocument("DeviceExtra")
sk = doc.addObject('Sketcher::SketchObject', 'S')
sk.addGeometry(Part.LineSegment(App.Vector(0, 0, 0), App.Vector(10, 0, 0)), False)
doc.recompute()
a = bridge.tessellate('S')
sk.addGeometry(Part.LineSegment(App.Vector(0, 0, 0), App.Vector(0, 10, 0)), False)
doc.recompute()
out.append('{"sketch_updates": %s}' % str(bridge.tessellate('S') != a).lower())

doc.openTransaction('add box')
Part.show(Part.makeBox(5, 5, 5), 'U')
doc.commitTransaction()
doc.recompute()
u1 = bridge.tessellate('U')
doc.undo(); doc.recompute(); doc.redo(); doc.recompute()
out.append('{"redo_same_mesh": %s, "cache": %s}' %
           (str(bridge.tessellate('U') == u1).lower(), json.dumps(bridge._mesh_cache.stats())))
result = "\n".join(out)
