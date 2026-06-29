"""geometry — ALL geometry duties for citygml2idf. Pure math (numpy/pyproj),
no XML. Takes lists of (x, y, z) points and returns normals, areas, oriented
rings, reprojected/recentred coordinates, and a role classified from a face's
normal. Nothing here imports the readers, so it stays independently testable.
"""
