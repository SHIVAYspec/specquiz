import json
import os

def get():
    def _loadJson(name):
        with open(os.path.join(os.path.dirname(__file__),f"{name}.json"),"r") as f:
            return json.load(f)
    DB = dict()
    iso3DB = _loadJson("iso3")
    for k,v in iso3DB.items():
        DB[k] = {
            "iso2" : k,
            "iso3": v
        }
    def _addToDB(prop):
        propDB = _loadJson(prop)
        for k in DB.keys():
            DB[k][prop] = propDB[k]
    props = [
        "capital",
        "continent",
        "currency",
        "names",
        "phone"
    ]
    for i in props:
        _addToDB(i)
    return DB