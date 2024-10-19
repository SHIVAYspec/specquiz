%%raw("import './eMap.css'")
%%raw("import 'leaflet/dist/leaflet.css'")

let _makeGeoJson = (answers: array<GameState.answerType>, giveUp: bool) => {
  let countryColor = giveUp ? "red" : "#85C1E9"
  let capitalColor = giveUp ? "red" : "black"
  answers
  ->Array.map(v => {
    switch v {
    | GameState.AnswerCountry(v) =>
      <LeafletReact.GeoJSON
        key={v.iso3 ++ "-names"}
        data={v.geoJsonFeature}
        eventHandlers={Some(
          EventHandlers.make(
            ~click=_ => Console.log("Clicked : " ++ v.names->Array.at(0)->Option.getUnsafe),
            (),
          ),
        )}
        style={Some(
          PathOptions.make(
            ~color="black",
            ~fillColor=countryColor,
            ~fillOpacity=0.20,
            ~weight=1,
            (),
          ),
        )}>
        {Some(
          <LeafletReact.Tooltip>
            <p> {React.string(v.names->Array.at(0)->Option.getUnsafe)} </p>
          </LeafletReact.Tooltip>,
        )}
      </LeafletReact.GeoJSON>
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
  let (answers, setAnswers) = React.useState(() => None)
  React.useEffect(() => {
    setAnswers(_ => None)
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
          let (_, answers) = v
          answers
          ->Map.values
          ->Core__Iterator.toArray
        }),
      )
      ->Rxjs.subscribe({
        next: v => {
          setAnswers(_ => Some(v))
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
          <LeafletReact.GeoJSON
            key={data.iso3}
            data={data.geoJsonFeature}
            eventHandlers={Some(
              EventHandlers.make(
                ~click=_ => Console.log("Clicked : " ++ data.names->Array.at(0)->Option.getUnsafe),
                (),
              ),
            )}
            style={Some(
              PathOptions.make(
                ~color="black",
                ~fillColor={countryAns || capitalAns ? "#A569BD" : "#FF0000"},
                ~fillOpacity={
                  countryAns || capitalAns
                    ? (countryAns ? 0.20 : 0.0) +. (capitalAns ? 0.20 : 0.0)
                    : 0.20
                },
                ~weight=1,
                (),
              ),
            )}>
            {Some(
              <LeafletReact.Tooltip>
                <p>
                  {React.string(
                    (countryAns ? data.names->Array.at(0)->Option.getUnsafe : "?") ++
                    " : " ++ (capitalAns ? data.capitals->Array.at(0)->Option.getUnsafe : "?"),
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
