import os
import sys
import re

ta_name = 'TA-suhlabs-eMASS'
pattern = re.compile(r"[\\/]etc[\\/]apps[\\/][^\\/]+[\\/]bin[\\/]?$")
new_paths = [path for path in sys.path if not pattern.search(path) or ta_name in path]
sys.path = new_paths

current_dir = os.path.dirname(os.path.realpath(__file__))
app_root = os.path.dirname(current_dir)
lib_dir = os.path.join(app_root, 'lib')

if lib_dir not in sys.path:
    sys.path.insert(0, lib_dir)
