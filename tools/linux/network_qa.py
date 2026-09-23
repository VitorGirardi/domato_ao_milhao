"""Exercise real ENet with two Linux processes and separate player profiles."""
import os
from pathlib import Path
import subprocess
import time

root = Path(__file__).resolve().parents[2]
qa = root / "test-results" / "linux" / "network"
qa.mkdir(parents=True, exist_ok=True)
flags = qa / ("flags-" + str(time.time_ns()))
flags.mkdir()
children = []
logs = []
try:
    for role in ("host", "client"):
        env = os.environ.copy()
        env["XDG_DATA_HOME"] = str(qa / role / "data")
        env["XDG_CONFIG_HOME"] = str(qa / role / "config")
        log = (qa / (role + ".log")).open("w")
        logs.append(log)
        process = subprocess.Popen(["godot", "--headless", "--audio-driver", "Dummy", "--path", str(root), "--script", "tests/test_network.gd", "--", role, str(flags)], cwd=root, env=env, stdout=log, stderr=subprocess.STDOUT)
        children.append(process)
        if role == "host":
            deadline = time.monotonic() + 90
            while not (flags / "host_ready").exists():
                if process.poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError("Host failed to become ready; inspect network/host.log")
                time.sleep(.2)
    for role, process in zip(("host", "client"), children):
        assert process.wait(timeout=180) == 0, role + " failed"
    for log in logs:
        log.close()
    for role in ("host", "client"):
        text = (qa / (role + ".log")).read_text()
        print(text)
        assert "NETWORK_QA_OK: " + role in text and "ERROR:" not in text, role + " failed"
finally:
    for process in children:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
    for log in logs:
        log.close()
