"""On-device checks for the mesh cache and bridge validation.

Not discovered by unittest (the filename does not start with test_). Run it on a
debug/qa build through the engine scripting hook:

    adb shell am start -n app.mobilecad.i18n.test/app.mobilecad.MainActivity \
        --es fcscript64 "$(base64 < engine/python/tests/device_check.py)"

The bridge wrapper logs the returned `result` string under logcat tag fcscript.
It covers shape edits, placement moves, App::Link updates and cache clearing on
a new document -- the cases where a stale cache would be visible.
"""
from mobilecad import bridge
import FreeCAD as App
import json
import Part
import time

out = []
out.append("ping=" + bridge.handle('{"op":"ping"}'))
out.append("badarg=" + bridge.handle('{"op":"properties","nmae":"Box"}'))

App.newDocument("DeviceCheck")
base = Part.makeBox(10, 10, 10)
for i in range(60):
    base = base.fuse(Part.makeBox(10, 10, 10, App.Vector(i * 12, 0, 0)))
Part.show(base, "Big")

t0 = time.monotonic()
first = bridge.tessellate("Big")
t1 = time.monotonic()
second = bridge.tessellate("Big")
t2 = time.monotonic()
out.append(json.dumps({"faces": len(base.Faces), "first_s": round(t1 - t0, 4),
                       "cached_s": round(t2 - t1, 6), "bytes": len(first),
                       "same": first == second, "cache": bridge._mesh_cache.stats()}))

obj = App.ActiveDocument.getObject("Big")
obj.Placement.Base.x = 5
App.ActiveDocument.recompute()
out.append('{"placement_changes_mesh": %s}' % str(bridge.tessellate("Big") != second).lower())

doc = App.ActiveDocument
link = doc.addObject("App::Link", "Link")
link.LinkedObject = doc.getObject("Big")
doc.recompute()
before = bridge.tessellate("Link")
obj.Shape = Part.makeBox(10, 10, 10)
doc.recompute()
out.append('{"link_updates": %s}' % str(bridge.tessellate("Link") != before).lower())

entries = bridge._mesh_cache.stats()["entries"]
bridge.handle('{"op":"new_document","name":"DeviceCheck2"}')
out.append('{"clear_on_new_document": %s, "entries_before": %d}' %
           (str(bridge._mesh_cache.stats()["entries"] == 0).lower(), entries))
result = "\n".join(out)
