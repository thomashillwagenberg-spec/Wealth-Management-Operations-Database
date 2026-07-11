#!/usr/bin/env python3
"""Generate a source-declared SPDX inventory without claiming package resolution.

This tool records centrally declared NuGet versions and container image tags. It
is useful when a full restore/build SBOM tool is unavailable. It does not prove
that dependencies restored, that transitive dependencies are complete, or that
images were pulled and scanned.
"""
from __future__ import annotations

import hashlib
import json
import re
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "artifacts" / "sbom" / "source-dependency-inventory.spdx.json"


def spdx_id(value: str) -> str:
    return "SPDXRef-" + re.sub(r"[^A-Za-z0-9.-]", "-", value)


def main() -> int:
    packages: list[dict[str, object]] = []
    relationships: list[dict[str, str]] = []
    root_id = "SPDXRef-DOCUMENTED-APPLICATION"

    central = ET.parse(ROOT / "Directory.Packages.props").getroot()
    for node in central.findall(".//PackageVersion"):
        name = node.attrib["Include"]
        version = node.attrib["Version"]
        pid = spdx_id(f"nuget-{name}-{version}")
        packages.append({
            "name": name,
            "SPDXID": pid,
            "versionInfo": version,
            "downloadLocation": f"https://www.nuget.org/packages/{name}/{version}",
            "filesAnalyzed": False,
            "supplier": "NOASSERTION",
            "licenseConcluded": "NOASSERTION",
            "licenseDeclared": "NOASSERTION",
            "copyrightText": "NOASSERTION",
            "externalRefs": [{
                "referenceCategory": "PACKAGE-MANAGER",
                "referenceType": "purl",
                "referenceLocator": f"pkg:nuget/{name}@{version}"
            }],
            "comment": "Declared centrally in Directory.Packages.props; restore and transitive dependency resolution were not executed in the packaging environment."
        })
        relationships.append({"spdxElementId": root_id, "relationshipType": "DEPENDS_ON", "relatedSpdxElement": pid})

    compose = yaml.safe_load((ROOT / "docker-compose.yml").read_text(encoding="utf-8"))
    for service_name, service in compose.get("services", {}).items():
        image = service.get("image") if isinstance(service, dict) else None
        if not image:
            continue
        name, _, tag = image.partition(":")
        version = tag or "latest"
        pid = spdx_id(f"container-{service_name}-{name}-{version}")
        packages.append({
            "name": name,
            "SPDXID": pid,
            "versionInfo": version,
            "downloadLocation": "NOASSERTION",
            "filesAnalyzed": False,
            "supplier": "NOASSERTION",
            "licenseConcluded": "NOASSERTION",
            "licenseDeclared": "NOASSERTION",
            "copyrightText": "NOASSERTION",
            "externalRefs": [{
                "referenceCategory": "PACKAGE-MANAGER",
                "referenceType": "purl",
                "referenceLocator": f"pkg:docker/{name}@{version}"
            }],
            "comment": f"Declared image for Compose service {service_name}; the image was not pulled or scanned in the packaging environment."
        })
        relationships.append({"spdxElementId": root_id, "relationshipType": "DEPENDS_ON", "relatedSpdxElement": pid})

    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    source_hash = hashlib.sha256((ROOT / "Directory.Packages.props").read_bytes() + (ROOT / "docker-compose.yml").read_bytes()).hexdigest()
    document = {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": "Wealth-Management-Operations-Platform-source-dependency-inventory",
        "documentNamespace": f"https://example.invalid/spdx/wmops/{source_hash}",
        "creationInfo": {
            "created": now,
            "creators": ["Tool: tools/generate_source_sbom.py", "Organization: Thomas Wagenberg portfolio project"],
            "comment": "Source-declared inventory only. Full restore/build SBOM generation was blocked because the .NET SDK and container tooling were unavailable."
        },
        "documentDescribes": [root_id],
        "packages": [{
            "name": "WealthManagementOperationsPlatform",
            "SPDXID": root_id,
            "versionInfo": "source",
            "downloadLocation": "NOASSERTION",
            "filesAnalyzed": False,
            "supplier": "Person: Thomas Wagenberg",
            "licenseConcluded": "NOASSERTION",
            "licenseDeclared": "NOASSERTION",
            "copyrightText": "NOASSERTION",
            "comment": "Educational reference application using fictional and synthetic data."
        }, *packages],
        "relationships": relationships
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT.relative_to(ROOT)} with {len(packages)} declared dependencies.")
    print("Classification: generated from source declarations; not a resolved runtime SBOM.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
