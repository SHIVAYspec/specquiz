type progressStatus = {
  country: bool,
  capital: bool,
}

type answerType =
  | AnswerCountry(CountriesDb.country)
  | AnswerCapital(CountriesDb.country)
  | GiveUp

type gameStateConfig = {
  countries: bool,
  capitals: bool,
  continents: dict<bool>,
}

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
  config: gameStateConfig,
}

let newGameState = (countriesDB: CountriesDb.countriesDB, config: gameStateConfig): (
  gameState,
  unit => unit,
) => {
  // let countriesList = CountriesDb.getCountriesFromFile()
  let countriesList: CountriesDb.countries =
    countriesDB.countries
    ->Array.reduce(Core__Dict.make(), (acc, v) => {
      switch acc->Core__Dict.get(v.continent) {
      | Some(arr) => arr->Array.push(v)
      | None => acc->Core__Dict.set(v.continent, [v])
      }
      acc
    })
    ->Dict.toArray
    ->Array.filter(v => {
      let (k, _) = v
      config.continents->Dict.get(k)->Option.isSome
    })
    ->Array.map(v => {
      let (_, v) = v
      v
    })
    ->Array.flat
  let length: int = countriesList->Array.length
  let numberOfQuestions = length * (config.capitals && config.countries ? 2 : 1)
  let progressStatusStream: Rxjs.t<
    Rxjs.subject<Rxjs.replay>,
    Rxjs.source<answerType>,
    answerType,
  > = Rxjs.Subject.makeReplay(numberOfQuestions + 1)
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
      if progressCounter.contents == numberOfQuestions {
        timerTickerID->Js.Global.clearInterval
        timer->Rxjs.complete
        if score.contents == -1 {
          score.contents = numberOfQuestions
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
      config,
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

let getMaxScorePossible = (state: gameState): int => {
  state.length * (state.config.capitals && state.config.countries ? 2 : 1)
}

let tryAnswerForCountry = (state: gameState, answer: string): bool => {
  if state.config.countries {
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
  } else {
    false
  }
}

let tryAnswerForCapital = (state: gameState, answer: string): bool => {
  if state.config.capitals {
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
  } else {
    false
  }
}

let tryAnswer = (state: gameState, answer: string): bool =>
  state->tryAnswerForCapital(answer) || state->tryAnswerForCountry(answer)

let giveUp = (state: gameState): unit => {
  state.progressStatusStream->Rxjs.next(GiveUp)
  state.timerTickerID->Js.Global.clearInterval
  state.timer->Rxjs.complete
  state.score.contents = state.length * (state.config.countries && state.config.capitals ? 2 : 1)
  state.progressStatusMap->Map.forEachWithKey((value, key) => {
    let countryData = state.countriesIso2Map->Map.get(key)->Option.getUnsafe
    if state.config.countries && !value.country {
      state.score.contents = state.score.contents - 1
      state.progressStatusStream->Rxjs.next(AnswerCountry(countryData))
    }
    if state.config.capitals && !value.capital {
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
  let make = (~db: CountriesDb.countriesDB, ~config: gameStateConfig, ~children: React.element) => {
    let (state, setState) = React.useState(() => None)
    React.useEffect0(() => {
      let (statelocal, dispose) = newGameState(db, config)
      setState(_ => Some(statelocal))
      Some(() => dispose())
    })
    switch state {
    | Some(state) => <Provider value={Some(state)}> {children} </Provider>
    | None => <EmptyMessage> "Loading Quiz ..." </EmptyMessage>
    }
  }
}
