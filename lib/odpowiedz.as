# odpowiedz.as — Odpowiedz class: wraps raw Http hash with typed accessors.
# Headers normalized to lowercase once in the constructor.
# JSON body lazily parsed and cached.

import("json")

modul Posel {
  klasa Odpowiedz {
    funkcja konstruktor(surowy_hash, zapytanie) {
      niech @surowa = surowy_hash
      niech @zapytanie = zapytanie
      niech @json_cache = nic
      niech @json_sparsowane = falsz

      niech @naglowki = {}
      niech surowe = surowy_hash["naglowki"]
      jesli surowe != nic {
        niech klucze = surowe.klucze()
        niech idx = 0
        dopoki idx < klucze.dlg() {
          niech klucz = klucze[idx]
          @naglowki[klucz.malymi()] = surowe[klucz]
          idx = idx + 1
        }
      }
    }

    funkcja status() { zwroc @surowa["status"] }
    funkcja cialo() { zwroc @surowa["cialo"] }
    funkcja wiadomosc() { zwroc @surowa["wiadomosc"] }

    # Lazy parse + cache. Throws BladSerializacji on invalid JSON.
    funkcja json() {
      jesli @json_sparsowane to zwroc @json_cache

      niech tresc = @surowa["cialo"]
      jesli tresc == nic to tresc = ""

      proba {
        @json_cache = Json::parsuj(tresc)
        @json_sparsowane = prawda
        zwroc @json_cache
      } zlap (e) {
        rzuc Posel::BladSerializacji.nowy(
          "Cannot parse response as JSON: " + e["wiadomosc"]
        )
      }
    }

    funkcja naglowki() { zwroc @naglowki }

    # Case-insensitive lookup via lowercased argument.
    funkcja naglowek(nazwa) {
      jesli nazwa == nic to zwroc nic
      zwroc @naglowki[nazwa.malymi()]
    }

    funkcja czy_sukces() { zwroc @surowa["czy_sukces"] }
    funkcja czy_przekierowanie() { zwroc @surowa["czy_przekierowanie"] }
    funkcja czy_blad_klienta() { zwroc @surowa["czy_blad_klienta"] }
    funkcja czy_blad_serwera() { zwroc @surowa["czy_blad_serwera"] }

    funkcja czy_blad() {
      niech s = @surowa["status"]
      jesli s == nic to zwroc falsz
      zwroc s >= 400
    }

    funkcja zapytanie() { zwroc @zapytanie }

    # Escape hatch — raw hash from Http for anything not exposed via methods.
    funkcja surowa() { zwroc @surowa }

    funkcja napis() {
      niech metoda_str = ""
      niech url_str = ""
      jesli @zapytanie != nic {
        metoda_str = @zapytanie.metoda()
        url_str = @zapytanie.url()
      }
      zwroc "<Odpowiedz " + status() + " " + metoda_str + " " + url_str + ">"
    }
  }
}
