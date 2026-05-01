# zapytanie.as — Zapytanie class: mutable request flowing through interceptors.
# URL is computed on demand from base + path + params, never cached.

import("./url")

modul Posel {
  klasa Zapytanie {
    funkcja konstruktor(konfig) {
      niech @metoda = konfig["metoda"]
      niech @bazowy_url = konfig["bazowy_url"]
      niech @sciezka = konfig["sciezka"]
      niech @naglowki = konfig["naglowki"]
      niech @cialo = konfig["cialo"]
      niech @parametry = konfig["parametry"]
      niech @limit_czasu = konfig["limit_czasu"]
      niech @max_przekierowan = konfig["max_przekierowan"]
      niech @oczekuje_json = konfig["oczekuje_json"]
      niech @rzucaj_bledy = konfig["rzucaj_bledy"]
      niech @meta = {}

      jesli @naglowki == nic to @naglowki = {}
      jesli @parametry == nic to @parametry = {}
      jesli @oczekuje_json == nic to @oczekuje_json = falsz
    }

    funkcja metoda() { zwroc @metoda }
    funkcja bazowy_url() { zwroc @bazowy_url }
    funkcja sciezka() { zwroc @sciezka }
    funkcja cialo() { zwroc @cialo }
    funkcja limit_czasu() { zwroc @limit_czasu }
    funkcja max_przekierowan() { zwroc @max_przekierowan }
    funkcja oczekuje_json() { zwroc @oczekuje_json }
    funkcja rzucaj_bledy() { zwroc @rzucaj_bledy }

    funkcja url() {
      niech bez_query = Posel::Url::polacz(@bazowy_url, @sciezka)
      zwroc Posel::Url::dodaj_parametry(bez_query, @parametry)
    }

    funkcja naglowki() { zwroc @naglowki }

    # Case-insensitive lookup.
    funkcja naglowek(nazwa) {
      niech szukana = nazwa.malymi()
      niech klucze = @naglowki.klucze()
      niech idx = 0
      dopoki idx < klucze.dlg() {
        niech klucz = klucze[idx]
        jesli klucz.malymi() == szukana to zwroc @naglowki[klucz]
        idx = idx + 1
      }
      zwroc nic
    }

    # Case-insensitive overwrite — finds existing key by lowercased compare,
    # otherwise inserts under given name.
    funkcja ustaw_naglowek(nazwa, wartosc) {
      niech szukana = nazwa.malymi()
      niech klucze = @naglowki.klucze()
      niech idx = 0
      dopoki idx < klucze.dlg() {
        niech klucz = klucze[idx]
        jesli klucz.malymi() == szukana {
          @naglowki[klucz] = wartosc
          zwroc nic
        }
        idx = idx + 1
      }
      @naglowki[nazwa] = wartosc
    }

    funkcja usun_naglowek(nazwa) {
      niech szukana = nazwa.malymi()
      niech klucze = @naglowki.klucze()
      niech idx = 0
      dopoki idx < klucze.dlg() {
        niech klucz = klucze[idx]
        jesli klucz.malymi() == szukana {
          @naglowki.usun(klucz)
          zwroc nic
        }
        idx = idx + 1
      }
    }

    funkcja parametry() { zwroc @parametry }

    funkcja ustaw_parametr(nazwa, wartosc) {
      @parametry[nazwa] = wartosc
    }

    funkcja usun_parametr(nazwa) {
      jesli @parametry.ma_klucz(nazwa) to @parametry.usun(nazwa)
    }

    funkcja ustaw_cialo(nowe) { @cialo = nowe }

    funkcja ustaw_limit_czasu(s) { @limit_czasu = s }

    funkcja ustaw_max_przekierowan(n) { @max_przekierowan = n }

    # No-arg returns whole hash; with key returns value under that key.
    funkcja meta(klucz = nic) {
      jesli klucz == nic to zwroc @meta
      zwroc @meta[klucz]
    }

    funkcja ustaw_meta(klucz, wartosc) {
      @meta[klucz] = wartosc
    }

    funkcja napis() {
      zwroc "<Zapytanie " + @metoda + " " + url() + ">"
    }
  }
}
