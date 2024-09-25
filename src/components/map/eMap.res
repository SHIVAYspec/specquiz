%%raw("import './eMap.css'")
%%raw("import 'leaflet/dist/leaflet.css'")

let _makeGeoJson = (answers: array<GameState.answerType>, giveUp: bool) => {
  let countryColor = giveUp ? "red" : "blue"
  let capitalColor = giveUp ? "red" : "black"
  answers
  ->Array.map(v => {
    switch v {
    | GameState.AnswerCountry(v) =>
      <LeafletReact.GeoJSON
        key={v.iso3 ++ "-names"}
        data={v.geoJsonFeature}
        style={Some(PathOptions.make(~color=countryColor, ~weight=1, ()))}
      />
    | GameState.AnswerCapital(v) =>
      <LeafletReact.GeoJSON
        key={v.iso3 ++ "-capital"}
        data={v.geoJsonFeature}
        style={Some(PathOptions.make(~color=capitalColor, ~fill=giveUp, ~weight=1, ()))}
      />
    | GameState.GiveUp => raise(Invalid_argument("Invalid element for map"))
    }
  })
  ->React.array
}

@react.component
let make = () => {
  let state: GameState.gameState =
    React.useContext(GameState.Context.stateContext)->Option.getUnsafe
  let (
    (answers, answersKey): (array<GameState.answerType>, array<GameState.answerType>),
    setAnswers,
  ) = React.useState(() => ([], []))
  React.useEffect(() => {
    let answerSub =
      state.progressStatusStream
      ->Rxjs.pipe2(
        Rxjs.scan((a, v, _) => {
          let (giveUp, answers, answersKey) = a
          switch v {
          | GameState.GiveUp => (true, answers, answersKey)
          | _ =>
            if giveUp {
              (true, answers, [v, ...answersKey])
            } else {
              (false, [v, ...answers], answersKey)
            }
          }
        }, (false, [], [])),
        Rxjs.map((v, _) => {
          let (_, a, b) = v
          (a, b)
        }),
      )
      ->Rxjs.subscribe({
        next: v => {
          setAnswers(_ => v)
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
    {if answers->Array.length + answersKey->Array.length == 0 {
      <EmptyMessage> "Enter your answers. The map would appear here." </EmptyMessage>
    } else {
      <LeafletReact.MapContainer center=(0.0, 0.0) zoom={2.0}>
        // <LeafletReact.TileLayer
        //   attribution={Some(
        //     "&copy; <a href=\"https://www.openstreetmap.org/copyright\">OpenStreetMap</a>",
        //   )}
        //   url={"https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"}
        // />
        {_makeGeoJson(answers, false)}
        {_makeGeoJson(answersKey, true)}
      </LeafletReact.MapContainer>
    }}
  </div>
}
