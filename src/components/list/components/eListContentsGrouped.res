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
        Rxjs.scan(
          (a, v, _) => {
            switch v {
            | GameState.GiveUp =>
              a
              ->Map.entries
              ->Core__Iterator.toArray
              ->Array.map(
                e => {
                  let (k, v) = e
                  (k, v->Array.concat([GameState.GiveUp]))
                },
              )
              ->Map.fromArray
            | AnswerCountry(e) =>
              a->Map.set(
                e.continent,
                a
                ->Map.get(e.continent)
                ->Option.getUnsafe
                ->Array.concat([GameState.AnswerCountry(e)]),
              )
              a
            | AnswerCapital(e) =>
              a->Map.set(
                e.continent,
                a
                ->Map.get(e.continent)
                ->Option.getUnsafe
                ->Array.concat([GameState.AnswerCapital(e)]),
              )
              a
            }
          },
          state.continentsCode2Map
          ->Dict.keysToArray
          ->Array.filter(v => state.config.continents->Dict.get(v)->Option.isSome)
          ->Array.map(v => (v, []))
          ->Map.fromArray,
        ),
        Rxjs.map((v, _) => {
          v
          ->Map.entries
          ->Core__Iterator.toArray
          ->Array.filter(
            e => {
              let (_, v) = e
              !(v->Array.length == 1 && v->Array.getUnsafe(0) == GameState.GiveUp)
            },
          )
          ->Array.map(
            e => {
              let (k, v) = e
              (
                state.continentsCode2Map->Dict.get(k)->Option.getUnsafe,
                switch v->Array.last {
                | Some(e) =>
                  e == GameState.GiveUp ? v->Array.slice(~start=0, ~end=v->Array.length - 2) : v
                | None => v
                },
              )
            },
          )
          ->Map.fromArray
        }),
      )
      ->Rxjs.subscribe({
        next: e => {
          setAnswers(_ => {
            Some(e)
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

  {
    switch answers {
    | Some(answers) =>
      answers
      ->Map.entries
      ->Core__Iterator.toArray
      ->Array.map(e => {
        let (k, v) = e
        <>
          <EListBullet.List>
            {[<EListBullet.Heading> {k} </EListBullet.Heading>]->Array.concat(
              v->Array.map(v => <EListBullet.AnswerBullet> {v} </EListBullet.AnswerBullet>),
            )}
          </EListBullet.List>
          <hr />
        </>
      })
      ->React.array
    | None => <h2> {React.string("Enter your answers. The list would appear here.")} </h2>
    }
  }
}
