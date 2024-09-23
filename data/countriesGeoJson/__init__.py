import json
import os
import sys
from collections import Counter

propertiesKeys = ("ADMIN","ISO_A2","ISO_A3")

def getCompressedGeoJsonFeatureList():
    geoJsonFiles = [20,25,35,55,100]
    geoJsonFiles = [os.path.join(os.path.dirname(__file__),f"countries{i}.geojson") for i in geoJsonFiles]
    geoJsonFeaturesLists = list()
    for i in geoJsonFiles:
        with open(i,"r") as f:
            geoJsonFeaturesLists.append(json.load(f)['features'])
    geoJsonFeaturesMapsList = list()
    for i in geoJsonFeaturesLists:
        geoJsonFeaturesMapsList.append({j['properties']['ADMIN']:j for j in i})
    geoJsonFeatureList = list()
    for i in geoJsonFeaturesMapsList[-1].keys():
        for maps in geoJsonFeaturesMapsList:
            if maps[i]['geometry'] == None:
                continue
            else:
                geoJsonFeatureList.append(maps[i])
                break
    # duplicates check / warning
    for i in propertiesKeys:
        for k,v in Counter([j['properties'][i] for j in geoJsonFeatureList]).items():
            if v != 1:
                print(f"WARNING : {i} {k} appeared {v} times",file=sys.stderr)
    return geoJsonFeatureList

def getCompressedGeoJsonFeatureMap():
    geoJsonFeatureMap = dict()
    for i in getCompressedGeoJsonFeatureList():
        props = i['properties']
        del i['properties']
        for e in propertiesKeys:
            geoJsonFeatureMap[f"{e}:{props[e]}"] = i
    return geoJsonFeatureMap