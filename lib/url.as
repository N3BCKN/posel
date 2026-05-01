# url.as — URL helpers: base+path joining, query params, hash merging.

import("http")

modul Posel {
  modul Url {

    funkcja czy_pelny(url) {
      jesli url == nic to zwroc falsz
      jesli url.dlg() < 7 to zwroc falsz

      niech p7 = url.wydziel(0, 7)
      jesli p7 == "http://" to zwroc prawda

      jesli url.dlg() < 8 to zwroc falsz
      niech p8 = url.wydziel(0, 8)
      jesli p8 == "https://" to zwroc prawda

      zwroc falsz
    }

    # Smart join. Full URL in `sciezka` skips base. Empty base returns path.
    # Otherwise joins with exactly one slash between.
    funkcja polacz(bazowy_url, sciezka) {
      jesli czy_pelny(sciezka) to zwroc sciezka
      jesli bazowy_url == nic to zwroc sciezka
      jesli bazowy_url == "" to zwroc sciezka
      jesli sciezka == nic to zwroc bazowy_url
      jesli sciezka == "" to zwroc bazowy_url

      niech baza_konczy = falsz
      jesli bazowy_url.dlg() > 0 {
        niech ostatni = bazowy_url.wydziel(bazowy_url.dlg() - 1, 1)
        jesli ostatni == "/" to baza_konczy = prawda
      }

      niech sciezka_zaczyna = falsz
      jesli sciezka.dlg() > 0 {
        niech pierwszy = sciezka.wydziel(0, 1)
        jesli pierwszy == "/" to sciezka_zaczyna = prawda
      }

      jesli baza_konczy {
        jesli sciezka_zaczyna {
          niech reszta = sciezka.wydziel(1, sciezka.dlg() - 1)
          zwroc bazowy_url + reszta
        }
        zwroc bazowy_url + sciezka
      }

      jesli sciezka_zaczyna to zwroc bazowy_url + sciezka
      zwroc bazowy_url + "/" + sciezka
    }

    funkcja dodaj_parametry(url, parametry) {
      jesli parametry == nic to zwroc url
      jesli parametry.pusty() to zwroc url

      niech query = Http::zbuduj_zapytanie(parametry)
      jesli query == "" to zwroc url

      jesli url.zawiera("?") to zwroc url + "&" + query
      zwroc url + "?" + query
    }

    # Merge two hashes; local wins on key conflict.
    funkcja scalaj_hashe(domyslne, lokalne) {
      niech wynik = {}
      jesli domyslne != nic to domyslne.klucze().kazdy(fn(k) { wynik[k] = domyslne[k] })
      jesli lokalne != nic to lokalne.klucze().kazdy(fn(k) { wynik[k] = lokalne[k] })
      zwroc wynik
    }
  }
}
