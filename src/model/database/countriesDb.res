type country = {
  iso2: string,
  iso3: string,
  continent: string,
  names: array<string>,
  capitals: array<string>,
  geoJsonFeature: LeafletReact.geoJson,
}

type countries = array<country>

type continents = dict<string>

type countriesDB = {
  countries: countries,
  continents: continents,
}

external toGeoJsonFeature: RescriptCore.JSON.t => LeafletReact.geoJson = "%identity"

let convertCountriesJsonToCountriesType = (countriesDBJson: JSON.t): countriesDB => {
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
  switch countriesDBJson {
  | Object(countriesDBJsonObj) => {
      countries: switch countriesDBJsonObj->Core__Dict.get("countries") {
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
      | None => raise(Invalid_argument("countries key not found in countriesDBJson"))
      },
      continents: switch countriesDBJsonObj->Core__Dict.get("continents") {
      | Some(continentsJson) =>
        switch continentsJson {
        | Object(continentsJsonObj) =>
          continentsJsonObj->Core__Dict.mapValues(continentNameJson =>
            switch continentNameJson {
            | String(continentNameJsonString) => continentNameJsonString
            | _ => raise(Invalid_argument("Continent name not a string"))
            }
          )
        | _ => raise(Invalid_argument("continents is not an object"))
        }
      | None => raise(Invalid_argument("continents key not found in countriesDBJson"))
      },
    }
  | _ => raise(Invalid_argument("CountriesDBJson is not an object"))
  }
}

let getCountriesFromFetchPromise = async (): JSON.t => {
  let data = await Fetch.get("./database/countriesWithGeoJson.json")
  let data = await data->Fetch.Response.json
  data
}

module CountriesDatabaseLoader = {
  @react.component
  let make = (~builder: countriesDB => React.element) => {
    let (database, setDatabase) = React.useState(() => None)
    React.useEffect0(() => {
      if database->Option.isNone {
        let dbp = getCountriesFromFetchPromise()
        let _ = dbp->Promise.then(async v => {
          setDatabase(_ => Some(convertCountriesJsonToCountriesType(v)))
        })
      }
      None
    })
    switch database {
    | Some(database) => builder(database)
    | None => <EmptyMessage> "Loading ..." </EmptyMessage>
    }
  }
}

// @module external countriesJsonFile: JSON.t = "./countries.json"
// @module external countriesWithGeoJsonJsonFile: JSON.t = "./countriesWithGeoJson.json"

// let getCountriesJson = (): JSON.t => {
//   switch countriesWithGeoJsonJsonFile {
//   | Object(countriesJsonFileObj) =>
//     switch countriesJsonFileObj->Core__Dict.get("default") {
//     | Some(countriesJson) => countriesJson
//     | None => raise(Invalid_argument("Default attribute not found in the file"))
//     }
//   | _ => raise(Invalid_argument("Invalid Json document"))
//   }
// }

// let getCountriesFromFile = (): countries => {
//   convertCountriesJsonToCountriesType(getCountriesJson())
// }

// let test = () => {
//   getCountriesFromFile()->Array.forEach(country => {
//     Console.log("==================================================")
//     Console.log(
//       country.iso2 ++
//       "->" ++
//       country.iso3 ++
//       "->" ++
//       country.continent ++
//       "->" ++
//       country.names->Array.at(0)->Option.getExn ++
//       "->" ++
//       country.capitals->Array.at(0)->Option.getExn,
//     )
//   })
// }
