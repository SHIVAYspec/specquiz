%%raw("import './eListBullet.css'")

module Bullet = {
  @react.component
  let make = (~className: string, ~children: string) => {
    <div className={"bullet " ++ className}>
      <p> {React.string(children)} </p>
    </div>
  }
}

module Heading = {
  @react.component
  let make = (~children: string) => {
    <div className={"bullet heading-bullet"}>
      <p> {React.string(children)} </p>
    </div>
  }
}

module AnswerBullet = {
  @react.component
  let make = (~children: GameState.answerType) => {
    switch children {
    | GameState.AnswerCountry(v) =>
      <Bullet key={v.iso3 ++ "-name"} className="country-bullet">
        {v.names->Array.at(0)->Option.getUnsafe}
      </Bullet>
    | GameState.AnswerCapital(v) =>
      <Bullet key={v.iso3 ++ "-capital"} className="capital-bullet">
        {v.capitals->Array.at(0)->Option.getUnsafe}
      </Bullet>
    | GameState.GiveUp => <Bullet key={"gaveup"} className="gaveup-bullet"> {"Gave up"} </Bullet>
    }
  }
}

module List = {
  @react.component
  let make = (~children: array<React.element>) => {
    <div className="bullet-list"> {React.array(children)} </div>
  }
}

module AnswerList = {
  @react.component
  let make = (~children: array<GameState.answerType>) => {
    <List> {children->Array.map(e => <AnswerBullet> {e} </AnswerBullet>)} </List>
  }
}
