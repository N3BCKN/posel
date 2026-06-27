# posel

A small, ergonomic HTTP client for [AlexScript](https://github.com/N3BCKN/alexscript) — inspired
by [Axios](https://axios-http.com/) and [HTTParty](https://github.com/jnunemaker/httparty).

Built on top of the native `Http` library, `posel` adds what a real-world client
needs: configurable instances, request and response interceptors, typed
exceptions for HTTP errors, and a parallel-friendly async API.

```alexscript
import("./posel/posel")

niech user = Posel::get_json("https://jsonplaceholder.typicode.com/users/1")
pokazl user["name"]
```

---

## Table of contents

- [Features](#features)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Configuring a client](#configuring-a-client)
- [Per-call options](#per-call-options)
- [Response object](#response-object)
- [Error handling](#error-handling)
- [Interceptors](#interceptors)
- [Async](#async)
- [Architecture](#architecture)
- [Limitations](#limitations)
- [License](#license)

---

## Features

- **All HTTP verbs** — `get`, `post`, `put`, `patch`, `delete`, `head`, `options`
- **JSON convenience methods** — `get_json`, `post_json`, etc., with auto
  serialization, parsing, and proper headers
- **Configurable client instances** with default headers, base URL,
  query parameters, timeout, and redirect limits
- **Typed exception hierarchy** — catch `BladNieZnaleziono` for 404s,
  `BladHttpKlienta` for any 4xx, `BladPosla` for anything from posel
- **Request and response interceptors** — Axios-style middleware chain
  (FIFO for requests, LIFO for responses)
- **Async variants for every method** — true parallel I/O via
  `uruchom_rownolegle` and `Obietnica.wszystkie`
- **Module facade** for one-off requests: `Posel::get(...)` skips
  client construction entirely

---

## Installation

Copy the `posel/` directory into your project and import the entry point:

```alexscript
import("./posel/posel")
```

That's it. No native dependencies beyond what AlexScript already ships
with (`Http`, `Json`).

---

## Quick start

```alexscript
import("./posel/posel")

# Module facade — uses an internal default client
niech user = Posel::get_json("https://api.example.com/users/1")
pokazl user["name"]

niech created = Posel::post_json("https://api.example.com/users", {
  "imie": "Jan",
  "wiek": 30
})
pokazl created["id"]
```

Module-level functions delegate to a lazily-initialized default client.
You can configure it once globally with `Posel::skonfiguruj({...})`.

---

## Configuring a client

For non-trivial use, create a `Posel::Klient` instance:

```alexscript
niech api = Posel::Klient.nowy({
  "bazowy_url": "https://api.example.com/v1",
  "naglowki": {
    "Authorization": "Bearer xyz123",
    "Accept": "application/json"
  },
  "parametry": { "api_key": "abc" },
  "limit_czasu": 10,
  "max_przekierowan": 5,
  "rzucaj_bledy": prawda
})

niech users = api.get_json("/users")
niech user_42 = api.get_json("/users/42")
api.delete("/users/42")
```

### Configuration options

| Key | Type | Default | Description |
|---|---|---|---|
| `bazowy_url` | string | `nic` | Prepended to relative paths. Full URLs in calls override it. |
| `naglowki` | hash | `{}` | Default headers. Merged with per-call headers (per-call wins). |
| `parametry` | hash | `{}` | Default query params. Merged with per-call params. |
| `limit_czasu` | integer | `30` | Timeout in seconds. |
| `max_przekierowan` | integer | `5` | Maximum redirects to follow. |
| `rzucaj_bledy` | bool | `prawda` | If true, raises typed exceptions on 4xx/5xx. |

### Mutating client configuration after construction

```alexscript
api.ustaw_naglowek_domyslny("Authorization", "Bearer new_token")
api.usun_naglowek_domyslny("X-Old-Header")
api.ustaw_parametr_domyslny("locale", "pl")
api.ustaw_bazowy_url("https://api2.example.com")
```

---

## Per-call options

Every method accepts an optional final `opcje` hash that overrides client
config for that one call. Hashes are merged (per-call wins on key
conflict), scalars are replaced.

```alexscript
api.get("/users", {
  "naglowki": { "X-Request-ID": "abc" },
  "parametry": { "limit": "10", "offset": "0" },
  "limit_czasu": 5,
  "rzucaj_bledy": falsz
})
```

---

## Response object

All non-JSON methods return a `Posel::Odpowiedz`:

```alexscript
niech odp = api.get("/users/1")

odp.status()              # 200
odp.cialo()               # raw response body string
odp.json()                # parsed JSON, lazily cached
odp.naglowek("content-type")   # case-insensitive lookup
odp.naglowki()            # hash, all keys lowercased

odp.czy_sukces()          # 2xx
odp.czy_przekierowanie()  # 3xx
odp.czy_blad_klienta()    # 4xx
odp.czy_blad_serwera()    # 5xx
odp.czy_blad()            # 4xx or 5xx

odp.zapytanie()           # the originating Posel::Zapytanie
odp.surowa()              # raw hash from Http (escape hatch)
```

`*_json` methods skip the wrapper and return parsed body directly:

```alexscript
niech user = api.get_json("/users/1")    # already a hash, not Odpowiedz
pokazl user["name"]
```

---

## Error handling

When `rzucaj_bledy` is `prawda` (the default), HTTP errors raise typed
exceptions. The hierarchy lets you catch broadly or narrowly:

```
WyjatekPodstawowy
└── BladPosla                  # everything from posel
    ├── BladSieci              # connection refused, DNS, reset, etc.
    ├── BladTimeoutu           # request timed out
    ├── BladSerializacji       # JSON parse failed
    └── BladHttp               # status >= 400
        ├── BladHttpKlienta    # 4xx
        │   ├── BladZleZapytanie       # 400
        │   ├── BladNieautoryzowany    # 401
        │   ├── BladBrakDostepu        # 403
        │   ├── BladNieZnaleziono      # 404
        │   ├── BladKonfliktu          # 409
        │   └── BladPrzeciazenia       # 429
        └── BladHttpSerwera    # 5xx
            ├── BladWewnetrzny         # 500
            ├── BladBramy              # 502
            ├── BladNiedostepny        # 503
            └── BladTimeoutuBramy      # 504
```

```alexscript
proba {
  niech user = api.get_json("/users/9999")
} zlap (e : Posel::BladNieZnaleziono) {
  pokazl "User not found"
} zlap (e : Posel::BladHttpKlienta) {
  pokazl "Other 4xx: " + e["wiadomosc"]
} zlap (e : Posel::BladSieci) {
  pokazl "Network problem: " + e["wiadomosc"]
} zlap (e : Posel::BladPosla) {
  pokazl "Anything else from posel"
}
```

If you'd rather inspect the response yourself, set `rzucaj_bledy: falsz`:

```alexscript
niech odp = api.get("/users/9999", { "rzucaj_bledy": falsz })
jesli odp.czy_sukces() {
  # ...
} albo {
  pokazl "Got " + odp.status()
}
```

---

## Interceptors

Interceptors are lambdas that receive a `Zapytanie` (request) or
`Odpowiedz` (response) and return one of the same type. Returning `nic`
passes the original through unchanged.

- **Request interceptors** run in registration order (FIFO)
- **Response interceptors** run in reverse order (LIFO) — the last
  registered is closest to the wire and sees the raw response first

### Logging

```alexscript
api.dodaj_interceptor_zapytania(fn(zap) {
  pokazl "→ " + zap.metoda() + " " + zap.url()
  zwroc zap
})

api.dodaj_interceptor_odpowiedzi(fn(odp) {
  pokazl "← " + odp.status() + " " + odp.zapytanie().url()
  zwroc odp
})
```

### Adding an auth header

```alexscript
api.dodaj_interceptor_zapytania(fn(zap) {
  zap.ustaw_naglowek("X-Request-ID", SecureRandom::uuid())
  zwroc zap
})
```

### Auto-refresh on 401

```alexscript
api.dodaj_interceptor_odpowiedzi(fn(odp) {
  jesli odp.status() == 401 {
    niech token = pobierz_nowy_token()
    api.ustaw_naglowek_domyslny("Authorization", "Bearer " + token)
    # Replay the original request through the full pipeline
    zwroc api.ponow(odp.zapytanie())
  }
  zwroc odp
})
```

### Measuring request time

```alexscript
api.dodaj_interceptor_zapytania(fn(zap) {
  zap.ustaw_meta("start", Czas::teraz().timestamp_f())
  zwroc zap
})

api.dodaj_interceptor_odpowiedzi(fn(odp) {
  niech ms = (Czas::teraz().timestamp_f() - odp.zapytanie().meta("start")) * 1000
  pokazl odp.zapytanie().url() + " took " + ms + "ms"
  zwroc odp
})
```

### Removing interceptors

```alexscript
api.usun_interceptory_zapytania()
api.usun_interceptory_odpowiedzi()
api.usun_wszystkie_interceptory()
```

---

## Async

Every sync method has an `_async` counterpart that returns an
`Obietnica`:

```alexscript
asynchroniczna funkcja main() {
  niech user = czekaj api.get_json_async("/users/1")
  pokazl user["name"]
}
uruchom(main)
```

### True parallel requests

`czekaj` on several promises in sequence is **still sequential** — each
`czekaj` blocks the current fiber. To run requests concurrently, wrap
each in `uruchom_rownolegle`:

```alexscript
asynchroniczna funkcja pobierz_wszystkich() {
  niech a = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/1") })
  niech b = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/2") })
  niech c = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/3") })

  niech wyniki = czekaj Obietnica.wszystkie([a, b, c])
  zwroc wyniki
}

uruchom(pobierz_wszystkich)
```

The three requests run concurrently — total wall time is roughly that of
the slowest single request, not the sum. AlexScript's fiber scheduler
suspends each request on socket I/O and lets the others make progress.

### Timeouts on async calls

```alexscript
asynchroniczna funkcja main() {
  proba {
    niech d = czekaj Obietnica.limit_czasu(api.get_async("/slow"), 1000)
  } zlap (e : BladLimituCzasu) {
    pokazl "took too long"
  }
}
```

### Async exceptions

`czekaj` re-raises rejection reasons as AlexScript exceptions, so the
typed exception hierarchy works the same way:

```alexscript
asynchroniczna funkcja main() {
  proba {
    czekaj api.get_json_async("/users/9999")
  } zlap (e : Posel::BladNieZnaleziono) {
    pokazl "404 from async too"
  }
}
```

---

## Architecture

```
posel/
├── posel.as       # entry point + module facade (Posel::get, etc.)
├── klient.as      # Klient class — sync + async methods, interceptors
├── zapytanie.as   # Zapytanie — mutable request flowing through pipeline
├── odpowiedz.as   # Odpowiedz — response wrapper with lazy JSON
├── pipeline.as    # interceptor chain runner
├── url.as         # URL joining and query string helpers
└── bledy.as       # exception hierarchy
```

### Request lifecycle

1. User calls `api.get("/users", opcje)`
2. Client builds a `Zapytanie` from its config + per-call options
3. Request interceptors run (FIFO)
4. `Http::get(...)` is invoked, errors are translated to typed exceptions
5. Raw hash is wrapped in `Odpowiedz`
6. Response interceptors run (LIFO)
7. If `rzucaj_bledy` and status ≥ 400, throws the matching `BladHttp...`
8. Returns `Odpowiedz` (or parsed JSON, for `_json` variants)

### Why a Zapytanie class?

Interceptors need to mutate things — headers, query params, body, even
the URL. Passing a hash around would force every interceptor to know the
shape; a class with named accessors makes interceptors readable and
catches typos at call time. The `meta()` slot is for interceptors to
attach their own data (timing, tracing, etc.) without polluting the
request itself.

---

## Limitations

The following are out of scope for v1:

- **Retry / exponential backoff** — straightforward to add as a response
  interceptor; a built-in helper may come in v2
- **Multipart uploads** — would require extending the native `Http`
  library
- **Streaming responses** beyond `Http::pobierz` to disk
- **Cookie jar** — read `Set-Cookie` and send `Cookie` manually if
  needed (an interceptor can automate this)
- **Request cancellation** — `Obietnica.limit_czasu` covers the timeout
  case; a true `AbortController` equivalent is not yet supported
- **HTTP/2** — `Http` uses Net::HTTP, which is HTTP/1.1 only

---

## License

MIT
