@react.component
let make = () => {
  let state: GameState.gameState =
    React.useContext(GameState.Context.stateContext)->Option.getUnsafe
  let (answers: array<GameState.answerType>, setAnswers) = React.useState(() => [])
  React.useEffect(() => {
    setAnswers(_ => [])
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

  {
    if answers->Array.length == 0 {
      <h2> {React.string("Enter your answers. The list would appear here.")} </h2>
    } else {
      {
        <EListBullet.AnswerList> answers </EListBullet.AnswerList>
      }
    }
  }
}
