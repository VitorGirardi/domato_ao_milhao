"""Build Zeca from the shared cartoon character authoring pipeline."""
import runpy
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
runpy.run_path(str(ROOT/'tools'/'build_cartoon_characters.py'))['build']('helper',True)