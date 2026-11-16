#!/usr/bin/env python3
"""Exercise actual dedicated Godot + HTTP/WebSocket proxy, using automated socket clients.
This is not a human or Android-device play test. Never publish identity secrets.
"""
from pathlib import Path
import json, os, socket, subprocess, sys, time, urllib.request, shutil
root = Path(__file__).resolve().parents[1]
builds = root / 'builds'
builds.mkdir(exist_ok=True)
def free_port():
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        return sock.getsockname()[1]
backend, frontend = free_port(), free_port()
env = os.environ.copy()
env.update(XDG_DATA_HOME=f'/tmp/dosa-seal-server-{frontend}', PORT=str(frontend), UPSTREAM_PORT=str(backend), SEAL_TEST_URL=f'ws://127.0.0.1:{frontend}')
godot = os.environ.get('GODOT_BIN', 'godot')
with (builds/'seal-server-results.txt').open('w') as server_log, (builds/'seal-proxy-results.txt').open('w') as proxy_log:
    server = subprocess.Popen([godot, '--headless', '--path', str(root), '--script', 'res://scripts/seal/server.gd', '--', f'--port={backend}'], env=env, stdout=server_log, stderr=subprocess.STDOUT)
    proxy = subprocess.Popen([sys.executable, str(root/'server/health_proxy.py')], env=env, stdout=proxy_log, stderr=subprocess.STDOUT)
    result = 1
    try:
        ready = False
        for _ in range(100):
            if server.poll() is not None:
                raise RuntimeError('Dedicated server exited during startup')
            try:
                with urllib.request.urlopen(f'http://127.0.0.1:{frontend}/health', timeout=.5) as reply:
                    ready = json.load(reply).get('protocol') == 3
            except OSError:
                pass
            if ready:
                break
            time.sleep(.1)
        if not ready:
            raise RuntimeError('Proxy health endpoint failed')
        print('PASS: real deployment HTTP health endpoint and backend readiness')
        env['XDG_DATA_HOME']=f'/tmp/dosa-seal-client-{frontend}'
        suite='seal_acquisition' if '--study-only' in sys.argv else ('seal_ui' if '--ui-only' in sys.argv else 'seal_network')
        display_args=['--headless'] if '--render' not in sys.argv else ['--audio-driver','Dummy','--max-fps','60']
        result=subprocess.call([sys.executable,str(root/'tools/run_godot_checked.py'),str(builds/(suite+'-results.txt')),godot,*display_args,'--path',str(root),'--script','res://tests/'+suite+'.gd'],env=env)
    finally:
        proxy.terminate();server.terminate()
        proxy.wait(timeout=10);server.wait(timeout=10)
text=(builds/'seal-server-results.txt').read_text()
if any(marker in text for marker in ['SCRIPT ERROR:', 'ERROR:']):
    print(text)
    result=1
shutil.rmtree(f'/tmp/dosa-seal-server-{frontend}', ignore_errors=True)
shutil.rmtree(f'/tmp/dosa-seal-client-{frontend}', ignore_errors=True)
sys.exit(result)
