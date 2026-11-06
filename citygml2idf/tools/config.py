"""
tools/config.py — where EnergyPlus is, and whether it is the right version.

Found in this order: the ENERGYPLUS_EXE setting -> `energyplus` on the system PATH -> a clear
error. It must be the version our IDFs are written for (writer.EPLUS_VERSION).
"""

import os
import shutil
import subprocess

from ..write.writer import EPLUS_VERSION


def find_energyplus():
    """The path of the EnergyPlus program: ENERGYPLUS_EXE if set, else the PATH; stops if none."""
    path = os.environ.get("ENERGYPLUS_EXE")
    if path:
        if not os.path.isfile(path):
            raise SystemExit(f"ENERGYPLUS_EXE is set to '{path}', but no file is there.")
        return path
    path = shutil.which("energyplus")
    if path is None:
        raise SystemExit(f"EnergyPlus not found. Install EnergyPlus {EPLUS_VERSION} and set "
                         f"ENERGYPLUS_EXE to its energyplus program (or put it on the PATH).")
    return path


def check_energyplus_version(path):
    """Stop unless the EnergyPlus at `path` is version EPLUS_VERSION (the IDF's Version field)."""
    text = subprocess.run([path, "--version"], capture_output=True, text=True).stdout
    if f"Version {EPLUS_VERSION}." not in text:
        raise SystemExit(f"{path} is '{text.strip()}', but our IDFs are written for EnergyPlus "
                         f"{EPLUS_VERSION}. Set ENERGYPLUS_EXE to an EnergyPlus {EPLUS_VERSION} program.")
