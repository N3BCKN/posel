# 04_obsluga_bledow.as
#
# Full exception hierarchy in action.
# Tests: typed catches by status code, parent type catching (BladHttpKlienta
#        catches all 4xx), context recovery from caught exceptions,
#        rzucaj_bledy: falsz for inspect-and-decide flow,
#        BladSerializacji on invalid JSON, BladSieci on bad host.

import("../posel")

niech api = Posel::Klient.nowy({
  "bazowy_url": "https://jsonplaceholder.typicode.com"
})

pokazl "=== 1. Typowane lapanie po dokladnym statusie ==="
proba {
  api.get_json("/users/99999")
} zlap (e : Posel::BladNieZnaleziono) {
  pokazl "Zlapane jako BladNieZnaleziono: " + e["wiadomosc"]
}

pokazl ""
pokazl "=== 2. Lapanie przez parenta (4xx) ==="
proba {
  api.get_json("/users/99999")
} zlap (e : Posel::BladHttpKlienta) {
  pokazl "Zlapane jako BladHttpKlienta: status " + e["instancja"].status()
}

pokazl ""
pokazl "=== 3. Lapanie przez BladHttp (kazdy >= 400) ==="
proba {
  api.get_json("/users/99999")
} zlap (e : Posel::BladHttp) {
  pokazl "Zlapane jako BladHttp: status " + e["instancja"].status()
}

pokazl ""
pokazl "=== 4. Lapanie przez korzen biblioteki ==="
proba {
  api.get_json("/users/99999")
} zlap (e : Posel::BladPosla) {
  pokazl "Zlapane jako BladPosla: " + e["wiadomosc"]
}

pokazl ""
pokazl "=== 5. Wiele klauzul zlap — najpierw najbardziej szczegolowy ==="
proba {
  api.get_json("/users/99999")
} zlap (e : Posel::BladNieautoryzowany) {
  pokazl "401 (nie powinno trafic tu)"
} zlap (e : Posel::BladNieZnaleziono) {
  pokazl "404 — trafilo tutaj"
} zlap (e : Posel::BladHttpKlienta) {
  pokazl "Inne 4xx (nie powinno trafic tu)"
}

pokazl ""
pokazl "=== 6. Pelen kontekst wyjatku — Odpowiedz i Zapytanie ==="
proba {
  api.get_json("/posts/99999")
} zlap (e : Posel::BladHttp) {
  niech inst = e["instancja"]
  niech odp = inst.odpowiedz()
  niech zap = inst.zapytanie()
  pokazl "  URL ktory wybuchl: " + zap.url()
  pokazl "  Metoda: " + zap.metoda()
  pokazl "  Status: " + odp.status()
  pokazl "  Body wystarczajaco dlugie?: " + odp.cialo().dlg()
}

pokazl ""
pokazl "=== 7. Bez rzucania — inspect-and-decide ==="
niech odp = api.get("/users/99999", { "rzucaj_bledy": falsz })
jesli odp.czy_blad_klienta() {
  pokazl "  Wykryto 4xx: " + odp.status() + " — kontynuujemy bez wyjatku"
}

pokazl ""
pokazl "=== 8. Per-call rzucaj_bledy override ==="
api.ustaw_naglowek_domyslny("X-Test", "1")
niech bez_rzucania = api.get("/users/99999", { "rzucaj_bledy": falsz })
pokazl "  Klient ma rzucaj_bledy=prawda, ale per-call wylaczone"
pokazl "  Status: " + bez_rzucania.status() + ", nie wybuchlo"

pokazl ""
pokazl "=== 9. BladSieci dla nieistniejacego hosta ==="
niech zly_klient = Posel::Klient.nowy({
  "limit_czasu": 3
})
proba {
  zly_klient.get("https://nieistniejacy-host-zupelnie-12345.invalid/x")
} zlap (e : Posel::BladSieci) {
  pokazl "  Zlapane: BladSieci (DNS/connection)"
} zlap (e : Posel::BladPosla) {
  pokazl "  Zlapane jako ogolny BladPosla"
}

pokazl ""
pokazl "=== 10. BladSerializacji przy probie .json() na nie-JSON ==="
niech html_klient = Posel::Klient.nowy({})
niech html = html_klient.get("https://example.com/")
pokazl "  Otrzymalismy HTML, status: " + html.status()
proba {
  html.json()
} zlap (e : Posel::BladSerializacji) {
  pokazl "  Zlapane: BladSerializacji przy probie parsowania HTML jako JSON"
}
