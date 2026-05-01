# 03_interceptory.as
#
# Request and response interceptors — middleware chain pattern.
# Tests: dodaj_interceptor_zapytania/odpowiedzi, FIFO/LIFO ordering,
#        meta() for cross-interceptor communication, ponow() for retry,
#        interceptor exceptions propagating up.

import("../posel")
import("czas")

niech api = Posel::Klient.nowy({
  "bazowy_url": "https://jsonplaceholder.typicode.com"
})

pokazl "=== 1. Logger interceptor ==="
api.dodaj_interceptor_zapytania(fn(zap) {
  pokazl "  → " + zap.metoda() + " " + zap.url()
  zwroc zap
})

api.dodaj_interceptor_odpowiedzi(fn(odp) {
  pokazl "  ← " + odp.status() + " " + odp.zapytanie().url()
  zwroc odp
})

niech u = api.get_json("/users/1")
pokazl "Pobrano: " + u["name"]

pokazl ""
pokazl "=== 2. Header injection ==="
api.usun_wszystkie_interceptory()

api.dodaj_interceptor_zapytania(fn(zap) {
  zap.ustaw_naglowek("X-Request-ID", "req-12345")
  zap.ustaw_naglowek("X-Client-Version", "1.0.0")
  zwroc zap
})

niech odp = api.get("/users/1")
pokazl "Naglowki w zapytaniu: X-Request-ID = " +
  odp.zapytanie().naglowek("X-Request-ID")

pokazl ""
pokazl "=== 3. Pomiar czasu przez meta() ==="
api.usun_wszystkie_interceptory()

api.dodaj_interceptor_zapytania(fn(zap) {
  zap.ustaw_meta("start", Czas::teraz().timestamp_f())
  zwroc zap
})

api.dodaj_interceptor_odpowiedzi(fn(odp) {
  niech start = odp.zapytanie().meta("start")
  niech ms = (Czas::teraz().timestamp_f() - start) * 1000
  pokazl "  Czas zapytania: " + ms + "ms"
  zwroc odp
})

api.get("/users/1")
api.get("/posts/1")

pokazl ""
pokazl "=== 4. Kolejnosc — FIFO dla zapytan, LIFO dla odpowiedzi ==="
api.usun_wszystkie_interceptory()

api.dodaj_interceptor_zapytania(fn(zap) {
  pokazl "  REQ-1 (zarejestrowany pierwszy, uruchomiony pierwszy)"
  zwroc zap
})
api.dodaj_interceptor_zapytania(fn(zap) {
  pokazl "  REQ-2 (zarejestrowany drugi, uruchomiony drugi)"
  zwroc zap
})

api.dodaj_interceptor_odpowiedzi(fn(odp) {
  pokazl "  RES-1 (zarejestrowany pierwszy, uruchomiony jako DRUGI/ostatni)"
  zwroc odp
})
api.dodaj_interceptor_odpowiedzi(fn(odp) {
  pokazl "  RES-2 (zarejestrowany drugi, uruchomiony jako PIERWSZY/blizej sieci)"
  zwroc odp
})

api.get("/users/1")

pokazl ""
pokazl "=== 5. Replay zapytania przez ponow() ==="
api.usun_wszystkie_interceptory()

niech licznik_proby = 0
api.dodaj_interceptor_odpowiedzi(fn(odp) {
  licznik_proby = licznik_proby + 1
  jesli licznik_proby == 1 {
    pokazl "  Pierwsza proba — symulujemy retry"
    zwroc api.ponow(odp.zapytanie())
  }
  pokazl "  Druga proba — przepuszczamy"
  zwroc odp
})

niech wynik = api.get_json("/users/1")
pokazl "Liczba prob: " + licznik_proby
pokazl "Finalnie pobrano: " + wynik["name"]

pokazl ""
pokazl "=== 6. Wyjatek w interceptorze przerywa pipeline ==="
api.usun_wszystkie_interceptory()

api.dodaj_interceptor_zapytania(fn(zap) {
  jesli zap.url().zawiera("/users/666") {
    rzuc Posel::BladPosla.nowy("Zapytanie do /users/666 zablokowane")
  }
  zwroc zap
})

proba {
  api.get("/users/666")
} zlap (e : Posel::BladPosla) {
  pokazl "Przechwycone: " + e["wiadomosc"]
}

niech ok = api.get_json("/users/1")
pokazl "Po zablokowaniu, normalne zapytanie dziala: " + ok["name"]
