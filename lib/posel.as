# posel.as — entry point.
# Imports all files in dependency order, then exposes a facade:
# Posel::get/post/... that delegates to a lazily-initialized default client.

import("./bledy")
import("./url")
import("./zapytanie")
import("./odpowiedz")
import("./pipeline")
import("./klient")

# Default client state — file-scope because AS modules only allow uppercase
# constants inside `modul { }`.
globalna niech _posel_domyslny_klient = nic
globalna niech _posel_domyslna_konfig = {}

modul Posel {

  # ── Default client (lazy init) ───────────────────────

  funkcja domyslny_klient() {
    jesli _posel_domyslny_klient == nic {
      _posel_domyslny_klient = Posel::Klient.nowy(_posel_domyslna_konfig)
    }
    zwroc _posel_domyslny_klient
  }

  # Reset — builds a fresh client. Previously registered interceptors
  # on the default client are dropped (intentional — keep your own
  # instance if you want to preserve state).
  funkcja skonfiguruj(konfig) {
    _posel_domyslna_konfig = konfig
    _posel_domyslny_klient = Posel::Klient.nowy(konfig)
  }

  # Escape hatch — direct access to the default client.
  funkcja klient() {
    zwroc domyslny_klient()
  }

  # ── HTTP verbs (sync) ────────────────────────────────

  funkcja get(url, opcje = nic) {
    zwroc domyslny_klient().get(url, opcje)
  }

  funkcja post(url, cialo = nic, opcje = nic) {
    zwroc domyslny_klient().post(url, cialo, opcje)
  }

  funkcja put(url, cialo = nic, opcje = nic) {
    zwroc domyslny_klient().put(url, cialo, opcje)
  }

  funkcja patch(url, cialo = nic, opcje = nic) {
    zwroc domyslny_klient().patch(url, cialo, opcje)
  }

  funkcja delete(url, opcje = nic) {
    zwroc domyslny_klient().delete(url, opcje)
  }

  funkcja head(url, opcje = nic) {
    zwroc domyslny_klient().head(url, opcje)
  }

  funkcja options(url, opcje = nic) {
    zwroc domyslny_klient().options(url, opcje)
  }

  # ── JSON variants (sync) ─────────────────────────────

  funkcja get_json(url, opcje = nic) {
    zwroc domyslny_klient().get_json(url, opcje)
  }

  funkcja post_json(url, dane, opcje = nic) {
    zwroc domyslny_klient().post_json(url, dane, opcje)
  }

  funkcja put_json(url, dane, opcje = nic) {
    zwroc domyslny_klient().put_json(url, dane, opcje)
  }

  funkcja patch_json(url, dane, opcje = nic) {
    zwroc domyslny_klient().patch_json(url, dane, opcje)
  }

  funkcja delete_json(url, opcje = nic) {
    zwroc domyslny_klient().delete_json(url, opcje)
  }

  # ── HTTP verbs (async) ───────────────────────────────

  asynchroniczna funkcja get_async(url, opcje = nic) {
    zwroc czekaj domyslny_klient().get_async(url, opcje)
  }

  asynchroniczna funkcja post_async(url, cialo = nic, opcje = nic) {
    zwroc czekaj domyslny_klient().post_async(url, cialo, opcje)
  }

  asynchroniczna funkcja put_async(url, cialo = nic, opcje = nic) {
    zwroc czekaj domyslny_klient().put_async(url, cialo, opcje)
  }

  asynchroniczna funkcja patch_async(url, cialo = nic, opcje = nic) {
    zwroc czekaj domyslny_klient().patch_async(url, cialo, opcje)
  }

  asynchroniczna funkcja delete_async(url, opcje = nic) {
    zwroc czekaj domyslny_klient().delete_async(url, opcje)
  }

  asynchroniczna funkcja head_async(url, opcje = nic) {
    zwroc czekaj domyslny_klient().head_async(url, opcje)
  }

  asynchroniczna funkcja options_async(url, opcje = nic) {
    zwroc czekaj domyslny_klient().options_async(url, opcje)
  }

  # ── JSON variants (async) ────────────────────────────

  asynchroniczna funkcja get_json_async(url, opcje = nic) {
    zwroc czekaj domyslny_klient().get_json_async(url, opcje)
  }

  asynchroniczna funkcja post_json_async(url, dane, opcje = nic) {
    zwroc czekaj domyslny_klient().post_json_async(url, dane, opcje)
  }

  asynchroniczna funkcja put_json_async(url, dane, opcje = nic) {
    zwroc czekaj domyslny_klient().put_json_async(url, dane, opcje)
  }

  asynchroniczna funkcja patch_json_async(url, dane, opcje = nic) {
    zwroc czekaj domyslny_klient().patch_json_async(url, dane, opcje)
  }

  asynchroniczna funkcja delete_json_async(url, opcje = nic) {
    zwroc czekaj domyslny_klient().delete_json_async(url, opcje)
  }

  # ── Interceptors on the default client ───────────────

  funkcja dodaj_interceptor_zapytania(interceptor) {
    domyslny_klient().dodaj_interceptor_zapytania(interceptor)
  }

  funkcja dodaj_interceptor_odpowiedzi(interceptor) {
    domyslny_klient().dodaj_interceptor_odpowiedzi(interceptor)
  }

  funkcja usun_wszystkie_interceptory() {
    domyslny_klient().usun_wszystkie_interceptory()
  }
}
