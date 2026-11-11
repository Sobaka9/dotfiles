#!/usr/bin/env python3
"""Print a microphone's peak level every 200ms, one integer per line.

Usage: micpeak.py <pipewire node name>

Only peak numbers are printed; the audio itself is never stored. Used by the
audio panel, while it is open, to notice a mic muted on the device itself
(see AudioPanel.qml). Exits, taking pw-record with it, when stopped.
"""
import array
import signal
import subprocess
import sys

RATE = 48000
CHUNK = RATE // 5 * 2  # 200ms of mono 16-bit samples

rec = subprocess.Popen(
    ["pw-record", "--target", sys.argv[1], "--format", "s16",
     "--rate", str(RATE), "--channels", "1", "-"],
    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)


def stop(*_):
    rec.terminate()
    sys.exit(0)


signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)

try:
    while True:
        data = rec.stdout.read(CHUNK)
        if len(data) < 2:
            break
        samples = array.array("h", data[: len(data) // 2 * 2])
        print(max(abs(s) for s in samples), flush=True)
except BrokenPipeError:
    pass
finally:
    rec.terminate()
