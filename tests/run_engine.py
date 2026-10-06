"""Run disposable Factorio --create checks without touching installed mods or saves."""
import argparse
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

sys.stdout.reconfigure(encoding="utf-8")

parser = argparse.ArgumentParser()
parser.add_argument("factorio", type=pathlib.Path)
parser.add_argument("--space-age", action="store_true")
parser.add_argument("--save", type=pathlib.Path, help="Copy an existing save for player API checks; never overwrite the original")
args = parser.parse_args()
source = pathlib.Path(__file__).resolve().parents[1]
(source / "dist").mkdir(exist_ok=True)
work = pathlib.Path(tempfile.mkdtemp(prefix="teleport-ui-test-", dir=source / "dist"))
for name in ("saves", "script-output", "temp", "scenarios", "archive"):
    (work / name).mkdir()
mod = work / "mods" / "TeleportAnywhere"
mod.mkdir(parents=True)
for name in ("info.json", "control.lua", "data.lua", "scripts", "data", "locale", "tests"):
    origin = source / name
    if origin.is_dir():
        shutil.copytree(origin, mod / name)
    else:
        shutil.copy2(origin, mod / name)
control = mod / "control.lua"
control.write_text('local ui_tests = require("tests.engine")\n' + control.read_text(encoding="utf-8").replace(
    "script.on_init(setup_all_players)",
    'script.on_init(function() setup_all_players(); ui_tests.run() end)').replace(
    "script.on_configuration_changed(setup_all_players)",
    'script.on_configuration_changed(function() setup_all_players(); ui_tests.run() end)'), encoding="utf-8")
mods = [{"name": "base", "enabled": True}, {"name": "TeleportAnywhere", "enabled": True}]
mods += [{"name": name, "enabled": args.space_age} for name in ("quality", "elevated-rails", "space-age")]
(work / "mods" / "mod-list.json").write_text(json.dumps({"mods": mods}), encoding="utf-8")
data = args.factorio.resolve().parents[2] / "data"
config = work / "config.ini"
config.write_text(f"[path]\nread-data={data.as_posix()}\nwrite-data={work.as_posix()}\n", encoding="utf-8")
if args.save:
    shutil.copy2(args.save, work / "input.zip")
    operation = ["--benchmark", str(work / "input.zip"), "--benchmark-ticks", "1", "--benchmark-runs", "1"]
else:
    operation = ["--create", str(work / "test.zip"), "--map-gen-seed", "12345"]
result = subprocess.run([str(args.factorio), "--config", str(config), "--mod-directory", str(work / "mods"), *operation],
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
output = result.stdout.decode("utf-8", errors="replace")
(work / "console.txt").write_text(output, encoding="utf-8")
print(f"Isolated test files: {work}")
print("\n".join(line for line in output.splitlines() if "TA " in line or "Error" in line or "tests/" in line))
if result.returncode or "TA ENGINE PASS:" not in output:
    print(output[-6000:])
    raise SystemExit(1)

