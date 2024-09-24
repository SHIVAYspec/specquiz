%%raw("import './emptyMessage.css'")

@react.component
let make = (~children: string) => {
  <div className="emptymessage">
    <h2> {React.string(children)} </h2>
  </div>
}
