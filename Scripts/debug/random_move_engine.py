import json
import random
import sys


def choose_move(board):
    empty_cells = [
        (x, y)
        for y, row in enumerate(board)
        for x, value in enumerate(row)
        if value == 0
    ]
    if not empty_cells:
        raise RuntimeError("No legal moves")
    return random.choice(empty_cells)


def main():
    for line in sys.stdin:
        try:
            request = json.loads(line)
            x, y = choose_move(request["board"])
            print(json.dumps({
                "x": x,
                "y": y,
                "debug": {"engine": "python_random_debug"},
            }), flush=True)
        except Exception as exc:
            print(json.dumps({
                "error": str(exc),
                "debug": {"engine": "python_random_debug"},
            }), flush=True)


if __name__ == "__main__":
    main()
