"""Two real Godot peers. Use --godot PATH; optional --gui also captures the visit.
All saves/logs are isolated under test-results; no user farm files are opened.
"""
from pathlib import Path
import argparse, os, subprocess, time
parser=argparse.ArgumentParser()
parser.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
parser.add_argument('--gui',action='store_true')
parser.add_argument('--test',default='test_network')
a=parser.parse_args();root=Path(__file__).resolve().parents[1]
flags=root/'test-results'/('network-'+str(time.time_ns()));flags.mkdir(parents=True)
processes=[]
try:
    for mode in ['host','client']:
        env=os.environ.copy();isolated=flags/mode;isolated.mkdir()
        env['APPDATA']=str(isolated);env['XDG_DATA_HOME']=str(isolated);env['XDG_CONFIG_HOME']=str(isolated/'config')
        log=open(flags/f'{mode}.log','w',encoding='utf-8')
        display=['--windowed','--resolution','1280x800'] if a.gui else ['--headless']
        proc=subprocess.Popen([a.godot,*display,'--audio-driver','Dummy','--path',str(root),'--script',f'res://tests/{a.test}.gd','--',mode,str(flags)],env=env,stdout=log,stderr=subprocess.STDOUT)
        processes.append((proc,log,mode))
        if mode=='host':
            deadline=time.monotonic()+90
            while not (flags/'host_ready').exists():
                if proc.poll() is not None or time.monotonic()>deadline:raise RuntimeError('Host did not start; '+str(flags))
                time.sleep(.1)
    for proc,log,mode in processes:
        proc.wait(timeout=160);log.close();output=(flags/f'{mode}.log').read_text()
        print(output,flush=True)
        assert proc.returncode==0 and ('NETWORK_QA_OK' in output or 'COOP_QA_OK' in output) and 'ERROR' not in output, (mode,flags)
    print('NETWORK_PAIR_OK',flags)
finally:
    for proc,log,mode in processes:
        if proc.poll() is None:proc.kill();proc.wait()
        log.close()
