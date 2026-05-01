# 05_rownolegle.as
#
# Async API + true parallel I/O via uruchom_rownolegle.
# Tests: single async call, parallel via uruchom_rownolegle + wszystkie,
#        timing comparison sync vs parallel, async exception propagation,
#        Obietnica.limit_czasu, all async variants from facade.

import("../posel")
import("czas")

niech api = Posel::Klient.nowy({
  "bazowy_url": "https://jsonplaceholder.typicode.com"
})

pokazl "=== 1. Pojedyncze async wywolanie ==="
asynchroniczna funkcja test_pojedynczy() {
  niech u = czekaj api.get_json_async("/users/1")
  pokazl "  Pobrano async: " + u["name"]
}
uruchom(test_pojedynczy)

pokazl ""
pokazl "=== 2. Sekwencyjne czekanie — to NIE jest parallel ==="
asynchroniczna funkcja sekwencyjne() {
  niech start = Czas::teraz().timestamp_f()

  niech u1 = czekaj api.get_json_async("/users/1")
  niech u2 = czekaj api.get_json_async("/users/2")
  niech u3 = czekaj api.get_json_async("/users/3")

  niech ms = (Czas::teraz().timestamp_f() - start) * 1000
  pokazl "  3 zapytania sekwencyjnie w " + ms + "ms"
  pokazl "  " + u1["name"] + ", " + u2["name"] + ", " + u3["name"]
}
uruchom(sekwencyjne)

pokazl ""
pokazl "=== 3. Prawdziwie rownolegle przez uruchom_rownolegle ==="
asynchroniczna funkcja rownolegle() {
  niech start = Czas::teraz().timestamp_f()

  niech a = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/1") })
  niech b = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/2") })
  niech c = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/3") })

  niech wyniki = czekaj Obietnica.wszystkie([a, b, c])

  niech ms = (Czas::teraz().timestamp_f() - start) * 1000
  pokazl "  3 zapytania rownolegle w " + ms + "ms"
  pokazl "  " + wyniki[0]["name"] + ", " + wyniki[1]["name"] + ", " + wyniki[2]["name"]
}
uruchom(rownolegle)

pokazl ""
pokazl "=== 4. Wieksza skala — 5 zapytan rownolegle ==="
# Note: explicit unrolled list rather than a loop, because lambdas inside
# `dopoki` capture loop variables by reference — by the time each lambda
# runs, the loop variable has its final value, and all requests would hit
# the same URL. A helper function with a parameter is the idiomatic
# workaround, but for this demo unrolling is clearer.
asynchroniczna funkcja duzo_rownoleglych() {
  niech start = Czas::teraz().timestamp_f()

  niech z1 = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/1") })
  niech z2 = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/2") })
  niech z3 = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/3") })
  niech z4 = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/4") })
  niech z5 = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/5") })

  niech wyniki = czekaj Obietnica.wszystkie([z1, z2, z3, z4, z5])
  niech ms = (Czas::teraz().timestamp_f() - start) * 1000
  pokazl "  5 zapytan w " + ms + "ms (sredni " + (ms / 5) + "ms na zapytanie)"
  pokazl "  Pierwsze imie: " + wyniki[0]["name"]
  pokazl "  Drugie imie: " + wyniki[1]["name"]
  pokazl "  Ostatnie imie: " + wyniki[4]["name"]
}
uruchom(duzo_rownoleglych)

pokazl ""
pokazl "=== 5. Async wyjatki — czekaj re-raises ==="
asynchroniczna funkcja async_z_404() {
  proba {
    czekaj api.get_json_async("/users/99999")
  } zlap (e : Posel::BladNieZnaleziono) {
    pokazl "  Async 404 zlapane prawidlowo: " + e["wiadomosc"]
  }
}
uruchom(async_z_404)

pokazl ""
pokazl "=== 6. Obietnica.limit_czasu — timeout na async ==="
asynchroniczna funkcja z_timeoutem() {
  niech wolny_klient = Posel::Klient.nowy({
    "bazowy_url": "https://httpbin.org",
    "limit_czasu": 30
  })
  proba {
    czekaj Obietnica.limit_czasu(
      wolny_klient.get_async("/delay/5"),
      1000
    )
    pokazl "  Niespodziewanie zdazyl"
  } zlap (e : BladLimituCzasu) {
    pokazl "  Timeout zadzialal — przerwane po 1s"
  } zlap (e) {
    pokazl "  Inny wyjatek: " + e["wiadomosc"]
  }
}
uruchom(z_timeoutem)

pokazl ""
pokazl "=== 7. Mieszane warianty async — JSON i raw ==="
asynchroniczna funkcja mieszane() {
  niech raw = uruchom_rownolegle(fn() { czekaj api.get_async("/users/1") })
  niech json_dane = uruchom_rownolegle(fn() { czekaj api.get_json_async("/users/2") })
  niech pojedynczy_post = uruchom_rownolegle(fn() {
    czekaj api.post_json_async("/posts", { "title": "async test", "userId": 1 })
  })

  niech wyniki = czekaj Obietnica.wszystkie([raw, json_dane, pojedynczy_post])
  pokazl "  Raw response status: " + wyniki[0].status()
  pokazl "  JSON dane: " + wyniki[1]["name"]
  pokazl "  Utworzony post ID: " + wyniki[2]["id"]
}
uruchom(mieszane)

pokazl ""
pokazl "=== 8. Fasada Posel::*_async dziala identycznie ==="
asynchroniczna funkcja fasada_async() {
  niech a = uruchom_rownolegle(fn() {
    czekaj Posel::get_json_async("https://jsonplaceholder.typicode.com/users/1")
  })
  niech b = uruchom_rownolegle(fn() {
    czekaj Posel::get_json_async("https://jsonplaceholder.typicode.com/users/2")
  })
  niech wyniki = czekaj Obietnica.wszystkie([a, b])
  pokazl "  Z fasady: " + wyniki[0]["name"] + " i " + wyniki[1]["name"]
}
uruchom(fasada_async)
