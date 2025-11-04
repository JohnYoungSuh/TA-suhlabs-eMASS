import os
import sys

ta_name = 'TA-securepro-eMASS'
ta_lib_name = 'lib'
pattern_list = [ta_name, ta_lib_name]


def get_paths_from_splunk_home(pattern_list):
    paths = []
    splunk_home = os.environ.get('SPLUNK_HOME')
    if splunk_home:
        for pattern in pattern_list:
            path = os.path.join(splunk_home, 'etc', 'apps', pattern)
            if os.path.exists(path):
                paths.append(path)
    return paths


def get_local_lib_path():
    paths = []
    current_dir = os.path.dirname(os.path.abspath(__file__))
    lib_dir = os.path.join(current_dir, '..', 'lib')
    if os.path.exists(lib_dir):
        paths.append(lib_dir)
    return paths


all_paths = get_paths_from_splunk_home(pattern_list) + get_local_lib_path()

for path in all_paths:
    if path not in sys.path:
        sys.path.insert(0, path)
