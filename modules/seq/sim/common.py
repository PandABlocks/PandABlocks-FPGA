from pathlib import Path


def get_top():
    current = Path(__file__).resolve()
    while not (current / '.git').exists():
        current = current.parent

    return current
