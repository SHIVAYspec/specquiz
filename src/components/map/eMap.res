%%raw("import './eMap.css'")
%%raw("import 'leaflet/dist/leaflet.css'")

@react.component
let make = () => {
  let state: GameState.gameState =
    React.useContext(GameState.Context.stateContext)->Option.getUnsafe
  let ((gaveup, answers), setAnswers) = React.useState(() => (false, None))
  React.useEffect(() => {
    setAnswers(_ => (false, None))
    let answerSub =
      state.progressStatusStream
      ->Rxjs.pipe2(
        Rxjs.scan((agg, v, _) => {
          let (gaveup, answers) = agg
          switch v {
          | GameState.GiveUp => (true, answers)
          | GameState.AnswerCountry(e) => {
              switch answers->Map.get(e.iso3) {
              | Some(x) => {
                  let (_, _, capital) = x
                  answers->Map.set(e.iso3, (e, !gaveup, capital))
                }
              | None => answers->Map.set(e.iso3, (e, !gaveup, false))
              }
              (gaveup, answers)
            }
          | GameState.AnswerCapital(e) => {
              switch answers->Map.get(e.iso3) {
              | Some(x) => {
                  let (_, country, _) = x
                  answers->Map.set(e.iso3, (e, country, !gaveup))
                }
              | None => answers->Map.set(e.iso3, (e, false, !gaveup))
              }
              (gaveup, answers)
            }
          }
        }, (false, Map.make())),
        Rxjs.map((v, _) => {
          let (gaveup, answers) = v
          (
            gaveup,
            answers
            ->Map.values
            ->Core__Iterator.toArray,
          )
        }),
      )
      ->Rxjs.subscribe({
        next: v => {
          let (gaveup, answers) = v
          setAnswers(_ => (gaveup, Some(answers)))
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
    {switch answers {
    | None => <EmptyMessage> "Enter your answers. The map would appear here." </EmptyMessage>
    | Some(e) =>
      <LeafletReact.MapContainer center=(0.0, 0.0) zoom={2.0}>
        // <LeafletReact.TileLayer
        //   attribution={Some(
        //     "&copy; <a href=\"https://www.openstreetmap.org/copyright\">OpenStreetMap</a>",
        //   )}
        //   url={"https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"}
        // />
        {e
        ->Array.map(v => {
          let (data, countryAns, capitalAns) = v
          let answered = countryAns || capitalAns
          <LeafletReact.GeoJSON
            key={data.iso3}
            data={data.geoJsonFeature}
            style={Some(
              PathOptions.make(
                ~color="black",
                ~fillColor={answered ? "#A569BD" : "#FF0000"},
                ~fillOpacity={
                  answered ? (countryAns ? 0.20 : 0.0) +. (capitalAns ? 0.20 : 0.0) : 0.25
                },
                ~weight=1,
                (),
              ),
            )}>
            {Some(
              <LeafletReact.Tooltip>
                <p>
                  {React.string(
                    (countryAns || gaveup ? data.names->Array.at(0)->Option.getUnsafe : "?") ++
                    " : " ++ (
                      capitalAns || gaveup ? data.capitals->Array.at(0)->Option.getUnsafe : "?"
                    ),
                  )}
                </p>
              </LeafletReact.Tooltip>,
            )}
          </LeafletReact.GeoJSON>
        })
        ->React.array}
      </LeafletReact.MapContainer>
    }}
  </div>
}
