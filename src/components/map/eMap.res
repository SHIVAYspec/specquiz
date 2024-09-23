%%raw("import './eMap.css'")
%%raw("import 'leaflet/dist/leaflet.css'")

@react.component
let make = () => {
  let state: GameState.gameState =
    React.useContext(GameState.Context.stateContext)->Option.getUnsafe
  let (answers: array<GameState.answerType>, setAnswers) = React.useState(() => [])
  React.useEffect(() => {
    let answerSub = state.progressStatusStream->Rxjs.subscribe({
      next: e => {
        setAnswers(countries => {
          [e, ...countries]
        })
      },
      complete: () => (),
      error: _ => (),
    })
    Some(
      () => {
        answerSub->Rxjs.unsubscribe
      },
    )
  }, [])
  <div className="eMap">
    <LeafletReact.MapContainer center=(0.0, 0.0) zoom={2.0}>
      // <LeafletReact.TileLayer
      //   attribution={Some(
      //     "&copy; <a href=\"https://www.openstreetmap.org/copyright\">OpenStreetMap</a>",
      //   )}
      //   url={"https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"}
      // />
      {answers
      ->Array.map(v => {
        switch v {
        | GameState.AnswerCountry(v) =>
          <LeafletReact.GeoJSON
            key={v.iso3 ++ "-names"}
            data={v.geoJsonFeature}
            style={Some(PathOptions.make(~color="blue", ~weight=1, ()))}
          />
        | GameState.AnswerCapital(v) =>
          <LeafletReact.GeoJSON
            key={v.iso3 ++ "-capital"}
            data={v.geoJsonFeature}
            style={Some(PathOptions.make(~color="black", ~fill=false, ~weight=1, ()))}
          />
        }
      })
      ->React.array}
    </LeafletReact.MapContainer>
  </div>
}
