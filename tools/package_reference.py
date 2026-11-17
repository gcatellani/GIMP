"""Package the independently tested GIMP push examples; no engine binaries needed.

Run: python tools/package_reference.py
Outputs installable provider/consumer ZIPs and a source ZIP. Refuses overwrite
unless --overwrite is explicitly supplied.
"""
from __future__ import annotations
import argparse
import io
import hashlib
import json
from pathlib import Path
import zipfile

VERSION = "0.0.1"
ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT.parent
OUTPUT = ((WORKSPACE / "Distribution" / "GIMP") if (WORKSPACE / "Source").is_dir()
          else ROOT / "Distribution" / "GIMP") / "Reference" / VERSION
SOURCE = ROOT / "experiments" / "value-push"


def write_zip(path: Path, entries: dict[str, bytes], overwrite: bool = False):
    if path.exists() and not overwrite:
        raise FileExistsError(f"Preserve existing reference archive: {path}")
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, content in sorted(entries.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 11, 17, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, content, compresslevel=9)
    with zipfile.ZipFile(io.BytesIO(buffer.getvalue())) as archive:
        assert archive.testzip() is None
        assert set(archive.namelist()) == set(entries)
        for name, content in entries.items():
            assert archive.read(name) == content, name
    path.write_bytes(buffer.getvalue())
    return hashlib.sha256(buffer.getvalue()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--overwrite", action="store_true", help="Explicitly replace the three existing reference ZIPs")
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    downloads = ROOT / "reference" / VERSION
    instructions = (downloads / "README.md").read_bytes()
    bundles = {}
    for role in ("Provider", "Consumer"):
        folder = SOURCE / role.lower() / f"GIMP-Push-{role}"
        descriptor = json.loads((folder / "GothicMod.json").read_text())
        assert descriptor["name"] == folder.name
        assert descriptor["modVersion"] == VERSION
        assert descriptor["dependencies"] == []
        entries = {f"{folder.name}/{p.relative_to(folder).as_posix()}": p.read_bytes()
                   for p in sorted(folder.rglob("*")) if p.is_file()}
        assert all(name.endswith((".as", ".json")) for name in entries)
        entries[f"{folder.name}/README.md"] = instructions
        bundles[f"{folder.name}-{VERSION}.zip"] = entries
    source_entries = {"README.md": instructions,
                      "tools/package_reference.py": Path(__file__).read_bytes(),
                      f"reference/{VERSION}/README.md": instructions}
    for p in sorted(SOURCE.rglob("*")):
        if p.is_file():
            source_entries[p.relative_to(ROOT).as_posix()] = p.read_bytes()
    bundles[f"GIMP-Reference-Sources-{VERSION}.zip"] = source_entries
    for name in bundles:
        if not args.overwrite and ((OUTPUT / name).exists() or (downloads / name).exists()):
            raise FileExistsError(f"Preserve existing versioned archive: {name}")
    hashes = []
    for name, entries in bundles.items():
        digest = write_zip(OUTPUT / name, entries, args.overwrite)
        (downloads / name).write_bytes((OUTPUT / name).read_bytes())
        hashes.append(f"{digest}  {name}")
        print(f"PASS {name}: CRC and {len(entries)} byte-matched entries")
    manifest = "\n".join(hashes) + "\n"
    (OUTPUT / "SHA256SUMS.txt").write_text(manifest, encoding="utf-8")
    (downloads / "SHA256SUMS.txt").write_text(manifest, encoding="utf-8")
    print(f"Output: {OUTPUT}")


if __name__ == "__main__":
    main()
