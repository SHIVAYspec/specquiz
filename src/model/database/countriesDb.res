type country = {
  iso2: string,
  iso3: string,
  continent: string,
  names: array<string>,
  capitals: array<string>,
  geoJsonFeature: LeafletReact.geoJson,
}

type countries = array<country>

@module external countriesJsonFile: JSON.t = "./countries.json"
@module external countriesWithGeoJsonJsonFile: JSON.t = "./countriesWithGeoJson.json"
external toGeoJsonFeature: RescriptCore.JSON.t => LeafletReact.geoJson = "%identity"

let getCountriesDB = (): countries => {
  let getStrOrElseRaiseError = (
    jsonObj: Core__Dict.t<RescriptCore.JSON.t>,
    key: string,
  ): string => {
    switch jsonObj->Core__Dict.get(key) {
    | Some(subJsonObj) =>
      switch subJsonObj {
      | String(str) => str
      | _ => raise(Invalid_argument("Key : %s is not of string type"))
      }
    | None => raise(Invalid_argument("Key : %s not found"))
    }
  }
  let getArrOfStrOrElseRaiseError = (
    objJsonObj: Core__Dict.t<RescriptCore.JSON.t>,
    key: string,
  ): array<string> => {
    switch objJsonObj->Core__Dict.get(key) {
    | Some(arrOfStrJson) =>
      switch arrOfStrJson {
      | Array(arrOfStrJsonArr) =>
        arrOfStrJsonArr->Array.map(strJson =>
          switch strJson {
          | String(str) => str
          | _ => raise(Invalid_argument("Key : %s is not of string type"))
          }
        )
      | _ => raise(Invalid_argument("Key : %s is not of array type"))
      }
    | None => raise(Invalid_argument("Key : %s not found"))
    }
  }
  switch countriesWithGeoJsonJsonFile {
  | Object(countriesJsonFileObj) =>
    switch countriesJsonFileObj->Core__Dict.get("default") {
    | Some(countriesJson) =>
      switch countriesJson {
      | Array(countriesJsonArray) =>
        countriesJsonArray->Array.map(countryJson => {
          switch countryJson {
          | Object(countryJsonObj) => {
              iso2: countryJsonObj->getStrOrElseRaiseError("iso2"),
              iso3: countryJsonObj->getStrOrElseRaiseError("iso3"),
              continent: countryJsonObj->getStrOrElseRaiseError("continent"),
              names: countryJsonObj->getArrOfStrOrElseRaiseError("names"),
              capitals: countryJsonObj->getArrOfStrOrElseRaiseError("capital"),
              geoJsonFeature: switch countryJsonObj->Core__Dict.get("geoJsonFeature") {
              | Some(geoJsonFeatureJson) => geoJsonFeatureJson->toGeoJsonFeature
              | None => raise(Invalid_argument("geoJsonFeature not found in country"))
              },
            }
          | _ => raise(Invalid_argument("CountryJson is not an object"))
          }
        })
      | _ => raise(Invalid_argument("CountriesJson is not an array"))
      }
    | None => raise(Invalid_argument("Default attribute not found in the file"))
    }
  | _ => raise(Invalid_argument("Invalid Json document"))
  }
}

let test = () => {
  getCountriesDB()->Array.forEach(country => {
    Console.log("==================================================")
    Console.log(
      country.iso2 ++
      "->" ++
      country.iso3 ++
      "->" ++
      country.continent ++
      "->" ++
      country.names->Array.at(0)->Option.getExn ++
      "->" ++
      country.capitals->Array.at(0)->Option.getExn,
    )
  })
}
