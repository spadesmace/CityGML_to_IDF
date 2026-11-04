"""
model/zone_physics.py — NOTE  what a zone holds besides its surfaces: today its infiltration interanl gain poeple ... will be added

Each value is read from the file only; one the file does not give is never invented (no E+
object + a warning). The writer turns each value into its E+ object.

  nrg3:ThermalZone/infiltrationRate -> Zone.infiltration_ach (1/h)
                                    -> ZoneInfiltration:DesignFlowRate (write/writer.py)
"""

from __future__ import annotations

from ..citygml.citygml_read import child_measure
from ..citygml.xml_io import warn
from .model import ABSENT, INVALID, OK, trace
from .units import to_reference


def infiltration_air_changes(doc, zone_element, zone_name):
    """The zone's air changes per hour from nrg3:infiltrationRate, and its provenance line.

    Returns
    -------
    (float or None, str)
        None when the file states no rate, its unit is unknown, or it is negative.

    Notes
    -----
    ADE XSD ThermalZoneType infiltrationRate (gml:MeasureType); E+ IDD
    ZoneInfiltration:DesignFlowRate N4 Air Changes per Hour (units 1/hr, minimum 0). Never
    invented: a made-up rate would drive the free-float temperature, which is the result.
    """
    raw, uom = child_measure(doc, zone_element, "nrg", "infiltrationRate")
    if raw is None:
        warn(f"zone {zone_name} states no nrg3:infiltrationRate; no infiltration modelled "
             f"(a sealed zone floats warm)")
        return None, trace(ABSENT, "no nrg3:infiltrationRate; no ZoneInfiltration object emitted")
    air_changes = to_reference("infiltrationRate", raw, uom,
                               context=f"zone '{zone_name}' nrg3:infiltrationRate")
    if air_changes is None or air_changes < 0:          # to_reference already warned on a bad uom
        return None, trace(INVALID, f"nrg3:infiltrationRate {raw} '{uom}' unusable "
                                    f"(bad unit or negative); no ZoneInfiltration object emitted")
    return air_changes, trace(OK, f"nrg3:infiltrationRate {raw} {uom or '1/h'} -> "
                                  f"{round(air_changes, 4)} 1/h (E+ AirChanges/Hour)")


def attach_zone_physics(doc, model):
    """Read each zone's own values from its nrg3:ThermalZone onto its Zone (in place)."""
    for building in model.buildings:
        for zone in building.zones:
            zone_element = doc.get_by_id(zone.name)              # Zone.name = the gml:id
            air_changes, note = infiltration_air_changes(doc, zone_element, zone.name)
            zone.infiltration_ach = air_changes
            zone.provenance["infiltration_ach"] = note
            # TODO internal gains, the next value for this module: follow nrg3:usageZone from
            # the ThermalZone to its nrg3:UsageZone (inline or xlink: doc.property_object) and
            # read internalHeatGains with its convective / latent / radiant fractions and its
            # schedules; add the fields to model.Zone, set them here, and write them in
            # write/writer.py (e.g. OtherEquipment + a schedule).
