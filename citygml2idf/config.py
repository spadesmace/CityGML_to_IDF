"""
config.py — global TEST flags for the step-by-step testing architecture
(the staged testing ladder is logged in process.md; the EnergyPlus rules these
stages verify are in EPLUS_RULES.md). The parser is ALWAYS full and robust; these flags only
GATE which path runs for a given test stage — they are scaffolding, not logic.

REAL-WORLD / PRODUCTION values:
    ENABLE_WINDOWS    = True
    FORCE_SINGLE_ZONE = False
    DEFAULT_WWR       = None        # never fabricate a window (golden rule, W1.4)

Flip them per stage to isolate a bug; the values below are the CURRENT stage we
are testing, not the production defaults.
"""

# False -> openings.py is skipped, every wall is solid/opaque (stages 1 & 3).
# True  -> run the window cascade (explicit -> ratio -> areas -> DEFAULT_WWR).
ENABLE_WINDOWS = True

# True  -> zones.py ignores thermalBoundary and merges the building into ONE hull
#          zone (stages 1 & 2).
# False -> real multizone: one E+ Zone per nrg3:ThermalZone, interzone via
#          explicit reciprocal BoundarySurface pairs with BC=Surface.
FORCE_SINGLE_ZONE = False

# TEST-ONLY. When a wall has NO window source (no explicit geometry, no
# openingToSurfaceRatio, no total/opaque areas), a float here forces a window of
# this window-to-wall ratio so we can exercise the window pipeline on a window-less
# building (e.g. B1). None = production behaviour: no source -> opaque (W1.4).
DEFAULT_WWR = None
