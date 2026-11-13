#!/usr/bin/env python3
"""Print the ids of PipeWire clients run by the given programs, one per line.

Usage: pw-clients.py <program> [<program>...]

A program matches on its binary or application name. The audio panel uses
this to hide streams from programs it can't otherwise tell apart: wallpaper
engine's video wallpapers play through mpv, and their streams only say "mpv";
only the client that owns them names the program behind it.
"""
import json
import subprocess
import sys

names = set(sys.argv[1:])
out = subprocess.run(["pw-dump"], capture_output=True, text=True, timeout=5).stdout
for obj in json.loads(out or "[]"):
    if obj.get("type") != "PipeWire:Interface:Client":
        continue
    props = (obj.get("info") or {}).get("props") or {}
    if props.get("application.process.binary") in names or props.get("application.name") in names:
        print(obj["id"])
