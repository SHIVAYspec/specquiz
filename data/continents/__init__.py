import json
import os

def getContinents():
    with open(os.path.join(os.path.dirname(__file__),"continents.json"),"r") as f:
        return json.load(f)