"""geometry — ALL geometry duties for citygml2idf. Pure math (numpy), no XML.
Takes lists of (x, y, z) points and returns normals, areas, oriented rings,
a min corner for recentring (coordinates assumed metric; no CRS reprojection),
and a role classified from a face's normal. Nothing here imports the readers,
so it stays independently testable.
"""
