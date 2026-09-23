"""Native Linux launcher + downloaded game, isolated from real player data."""
import json, os, pathlib, subprocess, time

root = pathlib.Path('test-results/launcher').resolve()
root.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
env['XDG_DATA_HOME'] = str(root / 'data')
env['XDG_CONFIG_HOME'] = str(root / 'config')
helper = pathlib.Path('launcher/ui/bin/updater-linux').resolve()
install = root / 'install'
def call(action):
    p = subprocess.run([str(helper), action, str(install)], env=env, capture_output=True, text=True, timeout=180)
    result = json.loads(p.stdout)
    assert p.returncode == 0 and result['OK'], (p.stdout, p.stderr)
    return result

call('update')
game = subprocess.Popen([str(helper), 'play', str(install)], env=env, stdout=subprocess.PIPE, text=True)
def close_window(title):
    for _ in range(200):
        lines = subprocess.check_output(['wmctrl', '-lp'], text=True).splitlines()
        found = [line.split()[0] for line in lines if title in line]
        if found:
            time.sleep(3)
            subprocess.run(['wmctrl', '-ic', found[0]], check=True)
            return
        time.sleep(.1)
    raise AssertionError('Window missing: ' + title)

try:
    time.sleep(2)
    assert call('status')['Running'], 'Game lock was not held'
    blocked = subprocess.run([str(helper), 'update', str(install)], env=env, capture_output=True, text=True, timeout=10)
    assert blocked.returncode != 0, 'Update allowed while playing'
    close_window('Do Mato')
    stdout, _ = game.communicate(timeout=30)
    assert game.returncode == 0 and json.loads(stdout)['OK'], stdout
finally:
    if game.poll() is None: game.kill()
log = (install / 'game.log').read_text()
assert 'ERROR' not in log, log
launcher = pathlib.Path('exports/launcher/DoMato-Launcher.x86_64').resolve()
with (root / 'launcher.log').open('w') as output:
    p = subprocess.Popen([str(launcher), '--', '--install-root=' + str(install)], env=env, stdout=output, stderr=subprocess.STDOUT)
    try:
        close_window('Do Mato ao Milhão - Launcher')
        p.wait(timeout=60)
        assert p.returncode == 0
    finally:
        if p.poll() is None: p.kill()
assert 'ERROR' not in (root / 'launcher.log').read_text()
print('LAUNCHER_LINUX_SMOKE_OK')
