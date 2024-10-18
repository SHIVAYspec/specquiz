%%raw("import './eList.css'")

type viewMode = None | UnGrouped | GroupedByContinent

module ViewModeSelectors = {
  module S = {
    @react.component
    let make = (
      ~label: string,
      ~value: viewMode,
      ~config: viewMode,
      ~setConfig: (viewMode => viewMode) => unit,
    ) => {
      let color = "selector-" ++ (value == config ? "" : "un") ++ "selected"
      <button onClick={_ => setConfig(_ => value)} className={"selector " ++ color}>
        {React.string(label)}
      </button>
    }
  }
  @react.component
  let make = (~config: viewMode, ~setConfig: (viewMode => viewMode) => unit) => {
    <div className="selectors">
      <S label="Off" value=None config setConfig />
      <S label="Ungrouped" value=UnGrouped config setConfig />
      <S label="Grouped" value=GroupedByContinent config setConfig />
    </div>
  }
}

module Line = {
  @react.component
  let make = () => {
    <div className="line" />
  }
}

@react.component
let make = () => {
  let (config, setConfig) = React.useState(() => GroupedByContinent)
  <div className="eList">
    <EListTotal />
    <Line />
    {switch config {
    | None =>
      <EListBullet.Bullet className="heading-bullet"> {"List display is off"} </EListBullet.Bullet>
    | UnGrouped => <EListContentsGrouped key={"grouped"} />
    | GroupedByContinent => <EListContentsUnGrouped key={"ungrouped"} />
    }}
    <Line />
    <ViewModeSelectors config setConfig />
    <Line />
  </div>
}
