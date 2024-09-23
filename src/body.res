@val @scope("visualViewport")
external addEventListener: (string, unit => unit) => unit = "addEventListener"

@val @scope("visualViewport")
external removeEventListener: (string, unit => unit) => unit = "removeEventListener"

@val @scope("visualViewport")
external innerWidth: int = "width"

@val @scope("visualViewport")
external innerHeight: int = "height"

@val
external alert: string => unit = "alert"

let useWidth = () => {
  let (width, setWidth) = React.useState(() => innerWidth)
  React.useEffect0(() => {
    let handleWindowResize = () => {
      setWidth(_ => innerWidth)
    }
    addEventListener("resize", handleWindowResize)
    let cleanUp = () => removeEventListener("resize", handleWindowResize)
    Some(cleanUp)
  })
  width
}

let useHeight = () => {
  let (height, setHeight) = React.useState(() => innerHeight)
  React.useEffect0(() => {
    let handleWindowResize = () => {
      setHeight(_ => innerHeight)
    }
    addEventListener("resize", handleWindowResize)
    let cleanUp = () => removeEventListener("resize", handleWindowResize)
    Some(cleanUp)
  })
  height
}

module Contents = {
  @react.component
  let make = () => {
    let height = useHeight()
    let width = useWidth()
    <div
      style={{
        marginLeft: "auto",
        marginRight: "auto",
        width: width->Int.toString ++ "px",
        height: height->Int.toString ++ "px",
      }}>
      <div
        style={{
          display: "flex",
          width: "100%",
          height: "calc(100% - 48px)",
        }}>
        <EMap />
        <EList />
      </div>
      <EInput />
    </div>
  }
}

@react.component
let make = () => {
  <GameState.Context>
    <Contents />
  </GameState.Context>
}
