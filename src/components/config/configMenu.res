%%raw("import './configMenu.css'")

@react.component
let make = (
  ~db: CountriesDb.countriesDB,
  ~setConfig: (option<GameState.gameStateConfig> => option<GameState.gameStateConfig>) => unit,
) => {
  let (countriesOption, setCountriesOption) = React.useState(() => true)
  let (capitalsOption, setCapitalsOption) = React.useState(() => false)
  let (selectedContinent, setSelectedContinents) = React.useState(() =>
    Core__Dict.fromArray(
      db.continents
      ->Dict.toArray
      ->Array.map(x => {
        let (k, _) = x
        (k, true)
      }),
    )
  )
  let valid: bool = React.useMemo3(() => {
    (countriesOption || capitalsOption) && selectedContinent->Core__Dict.toArray->Array.length != 0
  }, (countriesOption, capitalsOption, selectedContinent->Core__Dict.toArray->Array.length == 0))
  <div className="configMenu">
    <div className="configHeading">
      <h1 className="configHeadingText"> {React.string("Countries and capitals quiz")} </h1>
    </div>
    <div className="configMenuSubSection">
      <div
        className={"buttonBullet " ++ (
          countriesOption ? "selectedButtonBullet" : "unselectedButtonBullet"
        )}
        onClick={_ => setCountriesOption(v => !v)}>
        <p className={(countriesOption ? "" : "un") ++ "selectedText"}>
          {React.string("Countries")}
        </p>
      </div>
      <div
        className={"buttonBullet " ++ (
          capitalsOption ? "selectedButtonBullet" : "unselectedButtonBullet"
        )}
        onClick={_ => setCapitalsOption(v => !v)}>
        <p className={(capitalsOption ? "" : "un") ++ "selectedText"}>
          {React.string("Capitals")}
        </p>
      </div>
    </div>
    <div className="configMenuSubSection">
      {db.continents
      ->Core__Dict.toArray
      ->Array.map(x => {
        let (k, v) = x
        switch selectedContinent->Core__Dict.get(k) {
        | Some(_) =>
          <div
            key=k
            className="buttonBullet selectedButtonBullet"
            onClick={_ => {
              setSelectedContinents(data => {
                data->Core__Dict.delete(k)
                data->Core__Dict.copy
              })
            }}>
            <p className="selectedText"> {React.string(v)} </p>
          </div>
        | None =>
          <div
            key=k
            className="buttonBullet unselectedButtonBullet"
            onClick={_ => {
              setSelectedContinents(data => {
                data->Core__Dict.set(k, true)
                data->Core__Dict.copy
              })
            }}>
            <p className="unselectedText"> {React.string(v)} </p>
          </div>
        }
      })
      ->React.array}
    </div>
    <div className="configMenuSubSection">
      <div
        className={"buttonBullet submitButtonBullet " ++ (
          valid ? "submitButtonBulletReady" : "submitButtonBulletInvaid"
        )}
        onClick={_ => {
          if valid {
            setConfig(_ => Some({
              countries: countriesOption,
              capitals: capitalsOption,
              continents: selectedContinent,
            }))
          }
        }}>
        <p className="selectedText"> {React.string("Start")} </p>
      </div>
    </div>
  </div>
}
