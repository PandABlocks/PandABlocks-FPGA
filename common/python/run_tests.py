#!/usr/bin/env python
import os
import shutil
from pathlib import Path



def main():
    path = Path(os.path.dirname(os.path.realpath(__file__)))
    tests = open(f'{path}/tests_to_run.txt', 'r')
    for module in tests:
        print()
        print(f'* Testing module \033[1m{module.strip("\n")}\033[0m *'.center(shutil.get_terminal_size().columns))
        print("---------------------------------------------------".center(shutil.get_terminal_size().columns))
        os.system(f'python3 {path}/cocotb_timing_test_runner.py {module}')


if __name__ == "__main__":
    main()
