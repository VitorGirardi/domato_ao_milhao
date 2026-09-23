"""Exercise exported Windows launcher and managed game with isolated APPDATA."""
import ctypes, hashlib, json, os, pathlib, subprocess, time

base = pathlib.Path(__file__).resolve().parents[1]
qa = base / 'test-results' / ('launcher-smoke-' + str(time.time_ns()))
qa.mkdir(parents=True)
real = pathlib.Path(os.environ['APPDATA']) / 'Godot/app_userdata/Do Mato ao Milhão'
def hashes():
    return {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in real.glob('farm_v1*.json*')}
before = hashes()
env = os.environ.copy()
env['APPDATA'] = str(qa / 'appdata')
helper = base / 'launcher/ui/bin/updater-windows.exe'
install = base / 'test-results/launcher-public'
def call(action):
    p = subprocess.run([str(helper), action, str(install)], env=env, capture_output=True, text=True, encoding='utf-8', timeout=120)
    result = json.loads(p.stdout)
    assert p.returncode == 0 and result['OK'], (p.stdout, p.stderr)
    return result

def close_owned(pid):
    windows = []
    @ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)
    def enum(hwnd, _):
        owner = ctypes.c_ulong()
        ctypes.windll.user32.GetWindowThreadProcessId(hwnd, ctypes.byref(owner))
        if owner.value == pid and ctypes.windll.user32.IsWindowVisible(hwnd): windows.append(hwnd)
        return True
    for _ in range(100):
        ctypes.windll.user32.EnumWindows(enum, 0)
        if windows: break
        time.sleep(.1)
    assert windows, ('No owned window', pid)
    time.sleep(4)
    for hwnd in windows: ctypes.windll.user32.PostMessageW(hwnd, 0x0010, 0, 0)

call('update')
p = subprocess.Popen([str(helper), 'play', str(install)], env=env, stdout=subprocess.PIPE, text=True, encoding='utf-8')
try:
    time.sleep(2)
    assert call('status')['Running']
    blocked = subprocess.run([str(helper), 'update', str(install)], env=env, capture_output=True, timeout=10)
    assert blocked.returncode != 0
    raw = subprocess.check_output(['powershell', '-NoProfile', '-Command', f'Get-CimInstance Win32_Process -Filter "ParentProcessId = {p.pid}" | Select-Object -ExpandProperty ProcessId'], text=True)
    child = int(raw.strip())
    close_owned(child)
    stdout, _ = p.communicate(timeout=45)
    assert p.returncode == 0 and json.loads(stdout)['OK'], stdout
finally:
    if p.poll() is None: p.kill()
game_log = (install / 'game.log').read_text(encoding='utf-8')
assert 'ERROR' not in game_log, game_log
with (qa / 'launcher.log').open('w', encoding='utf-8') as log:
    app = subprocess.Popen([str(base / 'exports/launcher/DoMato-Launcher.exe'), '--', '--install-root=' + str(install)], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        time.sleep(5)
        close_owned(app.pid)
        app.wait(timeout=45)
        assert app.returncode == 0
    finally:
        if app.poll() is None: app.kill()
assert 'ERROR' not in (qa / 'launcher.log').read_text(encoding='utf-8')
assert before == hashes(), 'Real saves changed'
(qa / 'report.json').write_text(json.dumps({'result': 'LAUNCHER_WINDOWS_SMOKE_OK', 'save_before':before, 'save_after':hashes()}, indent=2), encoding='utf-8')
print('LAUNCHER_WINDOWS_SMOKE_OK', qa)
