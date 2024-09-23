%%raw("import './eList.css'")

module Bullet = {
  @react.component
  let make = (~className: string, ~children: string) => {
    <div className={"bullet " ++ className}>
      <p> {React.string(children)} </p>
    </div>
  }
}

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
  <div className="eList">
    {answers
    ->Array.map(v => {
      switch v {
      | GameState.AnswerCountry(v) =>
        <Bullet key={v.iso3 ++ "-name"} className="country-bullet">
          {v.names->Array.at(0)->Option.getUnsafe}
        </Bullet>
      | GameState.AnswerCapital(v) =>
        <Bullet key={v.iso3 ++ "-capital"} className="capital-bullet">
          {v.capitals->Array.at(0)->Option.getUnsafe}
        </Bullet>
      }
    })
    ->React.array}
  </div>
}
