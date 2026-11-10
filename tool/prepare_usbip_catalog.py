#!/usr/bin/env python3
"""Add issue #194's firmware to the checked-out USB/IP harness catalog.

The pinned upstream catalog omits 3.0.3. Both matrix generation and the runner
need its release mapping: the runner uses it to set the virtual firmware version.
Keep any upstream entry when a newer catalog supplies this release.
"""

import json
from pathlib import Path
import sys

catalog_path = Path(sys.argv[1]) / "compat/config/firmwares.yaml"
catalog = json.loads(catalog_path.read_text())
if not any(entry["id"] == "3.0.3" for entry in catalog["release_mappings"]):
    catalog["release_mappings"].append({
        "id": "3.0.3",
        "core_commit": "7644370f0c16d5b5e0d2f503e6c47bd39aaa0e2f",
        "core_tag": "3.0.3",
    })
    catalog_path.write_text(json.dumps(catalog, indent=2) + "\n")

# 3.0.3's virtual-card fabrication locks Admin, then attempts a touch-gated
# reset. Reuse upstream's existing simulation-only fix for that same procedure;
# the real applets and their authentication/key-generation logic stay intact.
harness_path = Path(sys.argv[1]) / "compat/runner/harness.py"
harness = harness_path.read_text()
core_sha = "7644370f0c16d5b5e0d2f503e6c47bd39aaa0e2f"
if f'"{core_sha}":' not in harness:
    marker = "CORE_COMPAT_PATCHES = {\n"
    if marker not in harness:
        raise RuntimeError("USB/IP compatibility patch registry has changed")
    harness_path.write_text(harness.replace(
        marker,
        marker + f'    "{core_sha}": ("core-3.1.0-fabrication.patch",),\n',
        1,
    ))
