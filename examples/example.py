import requests
import random
from os import path
from time import sleep

"""
USAGE:
    host or join game then run:
    python3 example.py
"""

def random_direction():
    return random.choice(['N', 'E', 'S', 'W'])

def main():
    game_id = input("game id: ")
    secret = input("secret: ")
    domain = input("domain: ")

    base_url = path.join(domain, "api", "game", game_id, "player", secret)

    resp = requests.get(path.join(base_url, "info"))
    state = resp.json()

    print(state)
    print(random_direction())

    while state["result"]["you"]["boom"] == False:
        sleep(0.5)

        resp = requests.get(path.join(base_url, "move", random_direction()))
        state = resp.json()
        print(state)

main()
