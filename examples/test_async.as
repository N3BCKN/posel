import("../posel")
import('czas')

# Sync — to co już działało:
niech user = Posel::get_json("https://jsonplaceholder.typicode.com/users/1")
pokazl user["name"]

# Sync z error handling:
proba {
  Posel::get_json("https://jsonplaceholder.typicode.com/posts/9999")
} zlap (e : Posel::BladNieZnaleziono) {
  pokazl "404 dziala"
}

# Async pojedynczy — sprawdza czy mechanizm działa:
asynchroniczna funkcja test_pojedynczy() {
  niech u = czekaj Posel::get_json_async("https://jsonplaceholder.typicode.com/users/1")
  pokazl "async: " + u["name"]
}
uruchom(test_pojedynczy)

# Async parallel — sprawdza prawdziwą równoległość:
asynchroniczna funkcja test_parallel() {
  niech start = Czas::teraz().timestamp_f()
  niech a = uruchom_rownolegle(fn() { czekaj Posel::get_json_async("https://jsonplaceholder.typicode.com/users/1") })
  niech b = uruchom_rownolegle(fn() { czekaj Posel::get_json_async("https://jsonplaceholder.typicode.com/users/2") })
  niech c = uruchom_rownolegle(fn() { czekaj Posel::get_json_async("https://jsonplaceholder.typicode.com/users/3") })
  niech wyniki = czekaj Obietnica.wszystkie([a, b, c])
  niech ms = Czas::teraz().timestamp_f() - start
  pokazl "Parallel 3 requests in " + ms + "ms"
  niech idx = 0
  dopoki idx < wyniki.dlg() {
    pokazl wyniki[idx]["name"]
    idx = idx + 1
  }
}
uruchom(test_parallel)