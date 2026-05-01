import("../posel")

# Async + dokładny match
asynchroniczna funkcja t1() {
  niech api = Posel::Klient.nowy({ "bazowy_url": "https://jsonplaceholder.typicode.com" })
  proba {
    czekaj api.get_json_async("/users/99999")
  } zlap (e : Posel::BladNieZnaleziono) {
    pokazl "T1 OK: " + e["wiadomosc"]
  }
}
uruchom(t1)

# Async + parent match
asynchroniczna funkcja t2() {
  niech api = Posel::Klient.nowy({ "bazowy_url": "https://jsonplaceholder.typicode.com" })
  proba {
    czekaj api.get_json_async("/users/99999")
  } zlap (e : Posel::BladHttpKlienta) {
    pokazl "T2 OK (parent match): " + e["wiadomosc"]
  }
}
uruchom(t2)