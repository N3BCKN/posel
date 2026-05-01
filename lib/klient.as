# klient.as — Posel::Klient: main client class.
# Holds config + interceptor lists. Exposes HTTP verbs (sync + async),
# JSON variants, retry via ponow(), config and interceptor management.

import("http")
import("json")
import("./bledy")
import("./url")
import("./zapytanie")
import("./odpowiedz")
import("./pipeline")

modul Posel {
  klasa Klient {

    funkcja konstruktor(konfig = nic) {
      jesli konfig == nic to konfig = {}

      niech @bazowy_url = konfig["bazowy_url"]
      niech @naglowki_domyslne = konfig["naglowki"]
      niech @parametry_domyslne = konfig["parametry"]
      niech @limit_czasu = konfig["limit_czasu"]
      niech @max_przekierowan = konfig["max_przekierowan"]
      niech @rzucaj_bledy = konfig["rzucaj_bledy"]

      jesli @naglowki_domyslne == nic to @naglowki_domyslne = {}
      jesli @parametry_domyslne == nic to @parametry_domyslne = {}
      jesli @limit_czasu == nic to @limit_czasu = 30
      jesli @max_przekierowan == nic to @max_przekierowan = 5
      jesli @rzucaj_bledy == nic to @rzucaj_bledy = prawda

      niech @interceptory_zapytania = []
      niech @interceptory_odpowiedzi = []
    }

    # ── HTTP verbs (sync) ─────────────────────────────────

    funkcja get(sciezka, opcje = nic) {
      zwroc _wykonaj(_zbuduj_zapytanie("GET", sciezka, nic, opcje, falsz))
    }

    funkcja post(sciezka, cialo = nic, opcje = nic) {
      zwroc _wykonaj(_zbuduj_zapytanie("POST", sciezka, cialo, opcje, falsz))
    }

    funkcja put(sciezka, cialo = nic, opcje = nic) {
      zwroc _wykonaj(_zbuduj_zapytanie("PUT", sciezka, cialo, opcje, falsz))
    }

    funkcja patch(sciezka, cialo = nic, opcje = nic) {
      zwroc _wykonaj(_zbuduj_zapytanie("PATCH", sciezka, cialo, opcje, falsz))
    }

    funkcja delete(sciezka, opcje = nic) {
      zwroc _wykonaj(_zbuduj_zapytanie("DELETE", sciezka, nic, opcje, falsz))
    }

    funkcja head(sciezka, opcje = nic) {
      zwroc _wykonaj(_zbuduj_zapytanie("HEAD", sciezka, nic, opcje, falsz))
    }

    funkcja options(sciezka, opcje = nic) {
      zwroc _wykonaj(_zbuduj_zapytanie("OPTIONS", sciezka, nic, opcje, falsz))
    }

    # ── JSON variants — return parsed body, not Odpowiedz ─

    funkcja get_json(sciezka, opcje = nic) {
      niech zap = _zbuduj_zapytanie("GET", sciezka, nic, opcje, prawda)
      _wymus_accept_json(zap)
      niech odp = _wykonaj(zap)
      zwroc odp.json()
    }

    funkcja post_json(sciezka, dane, opcje = nic) {
      niech tresc = _serializuj_json(dane)
      niech zap = _zbuduj_zapytanie("POST", sciezka, tresc, opcje, prawda)
      _wymus_naglowki_json(zap)
      niech odp = _wykonaj(zap)
      zwroc odp.json()
    }

    funkcja put_json(sciezka, dane, opcje = nic) {
      niech tresc = _serializuj_json(dane)
      niech zap = _zbuduj_zapytanie("PUT", sciezka, tresc, opcje, prawda)
      _wymus_naglowki_json(zap)
      niech odp = _wykonaj(zap)
      zwroc odp.json()
    }

    funkcja patch_json(sciezka, dane, opcje = nic) {
      niech tresc = _serializuj_json(dane)
      niech zap = _zbuduj_zapytanie("PATCH", sciezka, tresc, opcje, prawda)
      _wymus_naglowki_json(zap)
      niech odp = _wykonaj(zap)
      zwroc odp.json()
    }

    funkcja delete_json(sciezka, opcje = nic) {
      niech zap = _zbuduj_zapytanie("DELETE", sciezka, nic, opcje, prawda)
      _wymus_accept_json(zap)
      niech odp = _wykonaj(zap)
      zwroc odp.json()
    }

    # ── HTTP verbs (async) — return Obietnica ─────────────
    # Each just delegates to the sync variant inside an async function.
    # The fiber scheduler suspends on Net::HTTP socket I/O automatically,
    # so multiple concurrent requests via uruchom_rownolegle are truly parallel.

    asynchroniczna funkcja get_async(sciezka, opcje = nic) {
      zwroc get(sciezka, opcje)
    }

    asynchroniczna funkcja post_async(sciezka, cialo = nic, opcje = nic) {
      zwroc post(sciezka, cialo, opcje)
    }

    asynchroniczna funkcja put_async(sciezka, cialo = nic, opcje = nic) {
      zwroc put(sciezka, cialo, opcje)
    }

    asynchroniczna funkcja patch_async(sciezka, cialo = nic, opcje = nic) {
      zwroc patch(sciezka, cialo, opcje)
    }

    asynchroniczna funkcja delete_async(sciezka, opcje = nic) {
      zwroc delete(sciezka, opcje)
    }

    asynchroniczna funkcja head_async(sciezka, opcje = nic) {
      zwroc head(sciezka, opcje)
    }

    asynchroniczna funkcja options_async(sciezka, opcje = nic) {
      zwroc options(sciezka, opcje)
    }

    # ── JSON async variants ──────────────────────────────

    asynchroniczna funkcja get_json_async(sciezka, opcje = nic) {
      zwroc get_json(sciezka, opcje)
    }

    asynchroniczna funkcja post_json_async(sciezka, dane, opcje = nic) {
      zwroc post_json(sciezka, dane, opcje)
    }

    asynchroniczna funkcja put_json_async(sciezka, dane, opcje = nic) {
      zwroc put_json(sciezka, dane, opcje)
    }

    asynchroniczna funkcja patch_json_async(sciezka, dane, opcje = nic) {
      zwroc patch_json(sciezka, dane, opcje)
    }

    asynchroniczna funkcja delete_json_async(sciezka, opcje = nic) {
      zwroc delete_json(sciezka, opcje)
    }

    # ── Retry ────────────────────────────────────────────

    funkcja ponow(zapytanie) {
      zwroc _wykonaj(zapytanie)
    }

    asynchroniczna funkcja ponow_async(zapytanie) {
      zwroc _wykonaj(zapytanie)
    }

    # ── Config management ────────────────────────────────

    funkcja bazowy_url() { zwroc @bazowy_url }

    funkcja ustaw_bazowy_url(url) { @bazowy_url = url }

    funkcja naglowki_domyslne() { zwroc @naglowki_domyslne }

    funkcja parametry_domyslne() { zwroc @parametry_domyslne }

    funkcja ustaw_naglowek_domyslny(nazwa, wartosc) {
      @naglowki_domyslne[nazwa] = wartosc
    }

    funkcja usun_naglowek_domyslny(nazwa) {
      jesli @naglowki_domyslne.ma_klucz(nazwa) to @naglowki_domyslne.usun(nazwa)
    }

    funkcja ustaw_parametr_domyslny(nazwa, wartosc) {
      @parametry_domyslne[nazwa] = wartosc
    }

    funkcja usun_parametr_domyslny(nazwa) {
      jesli @parametry_domyslne.ma_klucz(nazwa) to @parametry_domyslne.usun(nazwa)
    }

    # ── Interceptors ─────────────────────────────────────

    funkcja dodaj_interceptor_zapytania(interceptor) {
      @interceptory_zapytania.dodaj(interceptor)
    }

    funkcja dodaj_interceptor_odpowiedzi(interceptor) {
      @interceptory_odpowiedzi.dodaj(interceptor)
    }

    funkcja usun_interceptory_zapytania() {
      @interceptory_zapytania = []
    }

    funkcja usun_interceptory_odpowiedzi() {
      @interceptory_odpowiedzi = []
    }

    funkcja usun_wszystkie_interceptory() {
      @interceptory_zapytania = []
      @interceptory_odpowiedzi = []
    }

    # ── Private ──────────────────────────────────────────

    prywatne

    funkcja _zbuduj_zapytanie(metoda, sciezka, cialo, opcje, oczekuje_json) {
      jesli opcje == nic to opcje = {}

      niech naglowki_l = opcje["naglowki"]
      niech parametry_l = opcje["parametry"]
      niech limit_l = opcje["limit_czasu"]
      niech max_l = opcje["max_przekierowan"]
      niech rzucaj_l = opcje["rzucaj_bledy"]

      niech naglowki = Posel::Url::scalaj_hashe(@naglowki_domyslne, naglowki_l)
      niech parametry = Posel::Url::scalaj_hashe(@parametry_domyslne, parametry_l)

      niech limit = @limit_czasu
      jesli limit_l != nic to limit = limit_l

      niech max_p = @max_przekierowan
      jesli max_l != nic to max_p = max_l

      niech rzucaj = @rzucaj_bledy
      jesli rzucaj_l != nic to rzucaj = rzucaj_l

      zwroc Posel::Zapytanie.nowy({
        "metoda": metoda,
        "bazowy_url": @bazowy_url,
        "sciezka": sciezka,
        "naglowki": naglowki,
        "cialo": cialo,
        "parametry": parametry,
        "limit_czasu": limit,
        "max_przekierowan": max_p,
        "oczekuje_json": oczekuje_json,
        "rzucaj_bledy": rzucaj
      })
    }

    funkcja _wykonaj(zapytanie) {
      niech zap = Posel::Pipeline::uruchom_interceptory_zapytania(
        zapytanie, @interceptory_zapytania
      )

      niech surowa = _wyslij_przez_http(zap)
      niech odp = Posel::Odpowiedz.nowy(surowa, zap)

      odp = Posel::Pipeline::uruchom_interceptory_odpowiedzi(
        odp, @interceptory_odpowiedzi
      )

      jesli zap.rzucaj_bledy() to _moze_rzucic_blad(odp, zap)

      zwroc odp
    }

    funkcja _wyslij_przez_http(zap) {
      niech metoda = zap.metoda()
      niech url = zap.url()
      niech naglowki = zap.naglowki()
      niech cialo = zap.cialo()

      niech opcje_http = {
        "timeout": zap.limit_czasu(),
        "przekierowania": zap.max_przekierowan()
      }

      proba {
        jesli metoda == "GET" to zwroc Http::get(url, naglowki, opcje_http)
        jesli metoda == "POST" to zwroc Http::post(url, cialo, naglowki, opcje_http)
        jesli metoda == "PUT" to zwroc Http::put(url, cialo, naglowki, opcje_http)
        jesli metoda == "PATCH" to zwroc Http::patch(url, cialo, naglowki, opcje_http)
        jesli metoda == "DELETE" to zwroc Http::delete(url, naglowki, opcje_http)
        jesli metoda == "HEAD" to zwroc Http::head(url, naglowki, opcje_http)
        jesli metoda == "OPTIONS" to zwroc Http::options(url, naglowki)

        rzuc Posel::BladPosla.nowy("Unsupported HTTP method: " + metoda)
      } zlap (e) {
        _przetlumacz_blad_http(e)
      }
    }

    # Translate Ruby Net::HTTP errors to typed Posel exceptions.
    # Heuristic on message text since native Http does not expose error types.
    funkcja _przetlumacz_blad_http(e) {
      niech wiadomosc = e["wiadomosc"]
      jesli wiadomosc == nic to wiadomosc = ""
      niech wm = wiadomosc.malymi()

      jesli wm.zawiera("timeout") to rzuc Posel::BladTimeoutu.nowy(wiadomosc)
      jesli wm.zawiera("timed out") to rzuc Posel::BladTimeoutu.nowy(wiadomosc)

      jesli wm.zawiera("refused") to rzuc Posel::BladSieci.nowy(wiadomosc)
      jesli wm.zawiera("unreachable") to rzuc Posel::BladSieci.nowy(wiadomosc)
      jesli wm.zawiera("reset") to rzuc Posel::BladSieci.nowy(wiadomosc)
      jesli wm.zawiera("connection") to rzuc Posel::BladSieci.nowy(wiadomosc)
      jesli wm.zawiera("dns") to rzuc Posel::BladSieci.nowy(wiadomosc)
      jesli wm.zawiera("getaddrinfo") to rzuc Posel::BladSieci.nowy(wiadomosc)
      jesli wm.zawiera("socket") to rzuc Posel::BladSieci.nowy(wiadomosc)
      jesli wm.zawiera("ssl") to rzuc Posel::BladSieci.nowy(wiadomosc)

      rzuc Posel::BladSieci.nowy(wiadomosc)
    }

    funkcja _moze_rzucic_blad(odp, zap) {
      niech status = odp.status()
      jesli status == nic to zwroc nic
      jesli status < 400 to zwroc nic

      niech wiadomosc = "HTTP " + status
      niech tekst_w = odp.wiadomosc()
      jesli tekst_w != nic {
        jesli tekst_w != "" to wiadomosc = wiadomosc + " " + tekst_w
      }

      _rzuc_dla_statusu(status, wiadomosc, odp, zap)
    }

    # Direct dispatch by status — avoids the parser limitation where
    # foo.nowy() is always parsed as ClassInstantiation("foo") regardless
    # of what foo holds.
    funkcja _rzuc_dla_statusu(status, k, odp, zap) {
      jesli status == 400 to rzuc Posel::BladZleZapytanie.nowy(k, odp, zap)
      jesli status == 401 to rzuc Posel::BladNieautoryzowany.nowy(k, odp, zap)
      jesli status == 403 to rzuc Posel::BladBrakDostepu.nowy(k, odp, zap)
      jesli status == 404 to rzuc Posel::BladNieZnaleziono.nowy(k, odp, zap)
      jesli status == 409 to rzuc Posel::BladKonfliktu.nowy(k, odp, zap)
      jesli status == 429 to rzuc Posel::BladPrzeciazenia.nowy(k, odp, zap)
      jesli status == 500 to rzuc Posel::BladWewnetrzny.nowy(k, odp, zap)
      jesli status == 502 to rzuc Posel::BladBramy.nowy(k, odp, zap)
      jesli status == 503 to rzuc Posel::BladNiedostepny.nowy(k, odp, zap)
      jesli status == 504 to rzuc Posel::BladTimeoutuBramy.nowy(k, odp, zap)

      jesli status < 500 to rzuc Posel::BladHttpKlienta.nowy(k, odp, zap)
      jesli status < 600 to rzuc Posel::BladHttpSerwera.nowy(k, odp, zap)
    }

    funkcja _serializuj_json(dane) {
      jesli dane == nic to zwroc "null"
      proba {
        zwroc Json::generuj(dane)
      } zlap (e) {
        rzuc Posel::BladSerializacji.nowy(
          "Cannot serialize data as JSON: " + e["wiadomosc"]
        )
      }
    }

    funkcja _wymus_naglowki_json(zap) {
      zap.ustaw_naglowek("Content-Type", "application/json")
      zap.ustaw_naglowek("Accept", "application/json")
    }

    funkcja _wymus_accept_json(zap) {
      zap.ustaw_naglowek("Accept", "application/json")
    }
  }
}
