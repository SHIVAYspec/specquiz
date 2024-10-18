type localAgg = {total: int, gaveup: bool}

@react.component
let make = () => {
  let state: GameState.gameState =
    React.useContext(GameState.Context.stateContext)->Option.getUnsafe
  let (answered, setAnswered) = React.useState(() => 0)
  React.useEffect(() => {
    setAnswered(_ => 0)
    let answerSub =
      state.progressStatusStream
      ->Rxjs.pipe2(Rxjs.scan((a, v, _) => {
          switch v {
          | GameState.GiveUp => {total: a.total, gaveup: true}
          | _ => {total: a.gaveup ? a.total : a.total + 1, gaveup: a.gaveup}
          }
        }, {total: 0, gaveup: false}), Rxjs.map((v, _) => v.total))
      ->Rxjs.subscribe({
        next: v => {
          setAnswered(_ => {
            v
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
  let questionsLength: int = React.useMemo(() => {
    (state.config.capitals ? state.length : 0) + (state.config.countries ? state.length : 0)
  }, [])

  <EListBullet.Bullet className="heading-bullet">
    {"Total : " ++ answered->Int.toString ++ " / " ++ questionsLength->Int.toString}
  </EListBullet.Bullet>
}
