"""Rebuild every shipped humanoid using the shared body, hands and rig."""
import runpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
api=runpy.run_path(str(ROOT/'tools/build_cartoon_characters.py'))
for name,stocky,vendor in [('farmer',False,False),('helper',True,False),('vendor',False,True),('cheesemaker',True,False),('dairyman',True,False)]:
    api['build'](name,stocky,vendor)
print('CHARACTERS_REBUILT_OK')
