type progressStatus = {
  country: bool,
  capital: bool,
}

type answerType = AnswerCountry(CountriesDb.country) | AnswerCapital(CountriesDb.country)

type gameState = {
  length: int,
  countriesIso2Map: Map.t<string, CountriesDb.country>,
  countriesNameToIso2Map: Map.t<string, string>,
  countriesCapitalToIso2Map: Map.t<string, string>,
  progressStatusMap: Map.t<string, progressStatus>,
  progressStatusStream: Rxjs.t<Rxjs.subject<Rxjs.replay>, Rxjs.source<answerType>, answerType>,
  score: ref<int>,
  timer: Rxjs.t<Rxjs.subject<Rxjs.behavior>, Rxjs.source<int>, int>,
  timerTickerID: Js.Global.intervalId,
}

let newGameState = (): (gameState, unit => unit) => {
  let countriesList = CountriesDb.getCountriesDB()
  let length: int = countriesList->Array.length
  let progressStatusStream: Rxjs.t<
    Rxjs.subject<Rxjs.replay>,
    Rxjs.source<answerType>,
    answerType,
  > = Rxjs.Subject.makeReplay(length * 2)
  let score = ref(-1)
  let timer: Rxjs.t<Rxjs.subject<Rxjs.behavior>, Rxjs.source<int>, int> = Rxjs.Subject.makeBehavior(
    0,
  )
  let counter = ref(0)
  let timerTickerID: Js.Global.intervalId = Js.Global.setInterval(() => {
    counter.contents = counter.contents + 1
    timer->Rxjs.next(counter.contents)
  }, 1000)
  let progressCounter = ref(0)
  let progressStatusStreamSub = progressStatusStream->Rxjs.subscribe({
    next: _ => {
      progressCounter.contents = progressCounter.contents + 1
      if progressCounter.contents == length * 2 {
        timerTickerID->Js.Global.clearInterval
        timer->Rxjs.complete
        if score.contents == -1 {
          score.contents = length * 2
        }
        let _ = setTimeout(() => {
          progressStatusStream->Rxjs.complete
        }, 1000)
      }
    },
    complete: () => (),
    error: _ => (),
  })

  (
    {
      length,
      countriesIso2Map: Map.fromArray(countriesList->Array.map(country => (country.iso2, country))),
      countriesNameToIso2Map: Map.fromArray(
        countriesList
        ->Array.map(country =>
          country.names->Array.map(name => (name->String.toLowerCase, country.iso2))
        )
        ->Array.flat,
      ),
      countriesCapitalToIso2Map: Map.fromArray(
        countriesList
        ->Array.map(country =>
          country.capitals->Array.map(name => (name->String.toLowerCase, country.iso2))
        )
        ->Array.flat,
      ),
      progressStatusMap: Map.fromArray(
        countriesList->Array.map(country => (country.iso2, {country: false, capital: false})),
      ),
      progressStatusStream,
      score,
      timer,
      timerTickerID,
    },
    () => {
      progressStatusStreamSub->Rxjs.unsubscribe
      timerTickerID->Js.Global.clearInterval
    },
  )
}

let getTimer = (state: gameState) => {
  state.timer->Rxjs.pipe(
    Rxjs.map((seconds, _) => {
      // "V1 : " ++ v1->Belt.Int.toString ++ " V2 : " ++ v2->Belt.Int.toString
      // (v1, v2)
      let hours = (seconds - seconds->Int.mod(3600)) / 3600
      let leftSeconds = seconds - hours * 3600
      let minutes = leftSeconds - leftSeconds->Int.mod(60) / 60
      let leftSeconds = leftSeconds - minutes * 60
      let timerDate = Date.makeWithYMDHMS(
        ~year=2000,
        ~month=1,
        ~date=1,
        ~hours,
        ~minutes,
        ~seconds=leftSeconds,
      )
      timerDate->Date.toTimeString->String.substring(~start=0, ~end=9)
    }),
  )
}

let tryAnswerForCountry = (state: gameState, answer: string): bool => {
  switch state.countriesNameToIso2Map->Map.get(answer->String.toLowerCase) {
  | Some(iso2Code) => {
      let status = state.progressStatusMap->Map.get(iso2Code)->Option.getUnsafe
      if status.country {
        false
      } else {
        state.progressStatusMap->Map.set(iso2Code, {country: true, capital: status.capital})
        state.progressStatusStream->Rxjs.next(
          AnswerCountry(state.countriesIso2Map->Map.get(iso2Code)->Option.getUnsafe),
        )
        true
      }
    }
  | None => false
  }
}

let tryAnswerForCapital = (state: gameState, answer: string): bool => {
  switch state.countriesCapitalToIso2Map->Map.get(answer->String.toLowerCase) {
  | Some(iso2Code) => {
      let status = state.progressStatusMap->Map.get(iso2Code)->Option.getUnsafe
      if status.capital {
        false
      } else {
        state.progressStatusMap->Map.set(iso2Code, {capital: true, country: status.country})
        state.progressStatusStream->Rxjs.next(
          AnswerCapital(state.countriesIso2Map->Map.get(iso2Code)->Option.getUnsafe),
        )
        true
      }
    }
  | None => false
  }
}

let tryAnswer = (state: gameState, answer: string): bool =>
  state->tryAnswerForCapital(answer) || state->tryAnswerForCountry(answer)

let giveUp = (state: gameState): unit => {
  state.timerTickerID->Js.Global.clearInterval
  state.timer->Rxjs.complete
  state.score.contents = state.length * 2
  state.progressStatusMap->Map.forEachWithKey((value, key) => {
    let countryData = state.countriesIso2Map->Map.get(key)->Option.getUnsafe
    if !value.country {
      state.score.contents = state.score.contents - 1
      state.progressStatusStream->Rxjs.next(AnswerCountry(countryData))
    }
    if !value.capital {
      state.score.contents = state.score.contents - 1
      state.progressStatusStream->Rxjs.next(AnswerCapital(countryData))
    }
  })
  state.progressStatusStream->Rxjs.complete
}

module Context = {
  let stateContext = React.createContext(None)
  module Provider = {
    let make = React.Context.provider(stateContext)
  }
  @react.component
  let make = (~children: React.element) => {
    let (state, setState) = React.useState(() => None)
    React.useEffect(() => {
      let (statelocal, dispose) = newGameState()
      setState(_ => Some(statelocal))
      Some(() => dispose())
    }, [])
    switch state {
    | Some(state) => <Provider value={Some(state)}> {children} </Provider>
    | None => <> </>
    }
  }
}
