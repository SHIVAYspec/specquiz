%%raw("import './eInput.css'")

@react.component
let make = () => {
  let state: GameState.gameState =
    React.useContext(GameState.Context.stateContext)->Option.getUnsafe
  let (answer, setAnswer) = React.useState(() => "")
  let (timer, setTimer) = React.useState(() => "")
  let (finished, setFinished) = React.useState(() => false)
  React.useEffect(() => {
    let sub =
      state
      ->GameState.getTimer
      ->Rxjs.subscribe({
        next: v => setTimer(_ => v),
        complete: () => setFinished(_ => true),
        error: _ => (),
      })
    Some(
      () => {
        sub->Rxjs.unsubscribe
      },
    )
  }, [])
  <div className="eInput">
    {if finished {
      <>
        <div className="score databox">
          {React.string(
            "Score : " ++
            state.score.contents->Int.toString ++
            " out of " ++
            state->GameState.getMaxScorePossible->Int.toString,
          )}
        </div>
        <div className="timer databox"> {React.string(timer)} </div>
        <div className="retry databox">
          <a href="."> {React.string("Retry")} </a>
        </div>
      </>
    } else {
      <>
        <input
          className="answerbox"
          value={answer}
          placeholder="Enter answer here."
          autoFocus=true
          onInput={event => {
            let out = event->JsxEventU.Form.target
            let out = out["value"]
            setAnswer(_ => out)
            if state->GameState.tryAnswer(out) {
              setAnswer(_ => "")
            }
          }}
        />
        <div className="timer databox">
          <p> {React.string(timer)} </p>
        </div>
        <div className="giveup databox" onClick={_ => state->GameState.giveUp}>
          <p> {React.string("Stop")} </p>
        </div>
      </>
    }}
  </div>
}
