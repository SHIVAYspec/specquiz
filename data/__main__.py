#!/usr/bin/env python3
import json
import os
import countriesGeoJson
import lukes
import countryIo

def main():
    countriesDB = list()
    with open(os.path.join(os.path.dirname(__file__),"config.json")) as f:
        config = json.load(f)
    countryIO = countryIo.get()
    for k,v in countryIO.items():
        if k in config:
            kconfig = config[k]
            if kconfig['quiz']:
                v['names'] = [v['names']]
                if 'altNames' in kconfig:
                    v['names'] += kconfig['altNames']
                v['capital'] = [v['capital']]
                if 'altCapitals' in kconfig:
                    v['capital'] += kconfig['altCapitals']
                countriesDB.append(v)
        else:
            print(f"WARNING : {k} / {v['names']} not found in config")
    # print(json.dumps(countriesDB))
    with open("countries.json","w") as f:
        json.dump(countriesDB,f)
    geoJsonFeatureMap = countriesGeoJson.getCompressedGeoJsonFeatureMap()
    for i in countriesDB:
        if "ISO_A2:" + i['iso2'] in geoJsonFeatureMap:
            # print(f"FOUND AT ISO_A2 : {i['names'][0]}")
            i['geoJsonFeature'] = geoJsonFeatureMap["ISO_A2:" + i['iso2']]
        elif "ISO_A3:" + i['iso3'] in geoJsonFeatureMap:
            # print(f"FOUND AT ISO_A3 : {i['names'][0]}")
            i['geoJsonFeature'] = geoJsonFeatureMap["ISO_A3:" + i['iso3']]
        else:
            for j in i['names']:
                if "ADMIN:" + j in geoJsonFeatureMap:
                    # print(f"FOUND AT ADMIN : {i['names'][0]}")
                    i['geoJsonFeature'] = geoJsonFeatureMap["ADMIN:" + j]
                    break
        if 'geoJsonFeature' not in i:
            print(f"WARNING : GEOJSON NOT FOUND : {i['names'][0]}")
    # print(json.dumps(countriesDB))
    with open("countriesWithGeoJson.json","w") as f:
        json.dump(countriesDB,f)

if __name__ == '__main__':
    main()
    # print(json.dumps(countriesGeoJson.getCompressedGeoJsonFeatureMap()))
    # print(json.dumps(lukes.get()))
    # print(json.dumps(countryIo.get()))