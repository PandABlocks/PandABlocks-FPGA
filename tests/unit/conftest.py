import sys
from pathlib import Path

# entity_runner reuses order_hdl_files from the timing test runner
COMMON_PYTHON_DIR = Path(__file__).parents[2] / 'common' / 'python'
sys.path.insert(1, str(COMMON_PYTHON_DIR.resolve()))
