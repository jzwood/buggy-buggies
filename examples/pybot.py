import requests
import random
from os import path
import sys
from time import sleep

"""
USAGE:
    host or join game then run:
    python3 pybot.py <domain> <game_id> <secret>

EXAMPLE:
    python3 pybot.py http://localhost:4000 a6bcfe56-7cc2-4eca-9f3c-786bce95a5e0 bac20489-ffb1-4fbc-925a-ae8e75dbdd55
"""

def random_direction():
    return random.choice(['N', 'E', 'S', 'W'])

def main():
    [_script, domain, game_id, secret] = sys.argv

    base_url = path.join(domain, "api", "game", game_id, "player", secret)

    resp = requests.get(path.join(base_url, "info"))
    state = resp.json()

    print(state)
    crashed = False

    while not crashed:
        sleep(0.5)
        resp = requests.get(path.join(base_url, "move", random_direction()))
        state = resp.json()
        if state["success"]:
            crashed = state["result"]["you"]["boom"]
            print(state)
    print("crashed")

main()
