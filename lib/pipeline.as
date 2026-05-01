# pipeline.as — runs request/response interceptor chains.
# Request: FIFO. Response: LIFO (last registered runs first, closest to wire).
# Returning nic from an interceptor passes the original through unchanged.

modul Posel {
  modul Pipeline {

    funkcja uruchom_interceptory_zapytania(zapytanie, interceptory) {
      jesli interceptory == nic to zwroc zapytanie
      jesli interceptory.dlg() == 0 to zwroc zapytanie

      niech aktualne = zapytanie
      niech idx = 0
      dopoki idx < interceptory.dlg() {
        niech interceptor = interceptory[idx]
        niech wynik = interceptor(aktualne)
        jesli wynik != nic to aktualne = wynik
        idx = idx + 1
      }
      zwroc aktualne
    }

    funkcja uruchom_interceptory_odpowiedzi(odpowiedz, interceptory) {
      jesli interceptory == nic to zwroc odpowiedz
      jesli interceptory.dlg() == 0 to zwroc odpowiedz

      niech aktualna = odpowiedz
      niech idx = interceptory.dlg() - 1
      dopoki idx >= 0 {
        niech interceptor = interceptory[idx]
        niech wynik = interceptor(aktualna)
        jesli wynik != nic to aktualna = wynik
        idx = idx - 1
      }
      zwroc aktualna
    }
  }
}
