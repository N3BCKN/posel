# 01_podstawowe.as
#
# Module-level facade: one-off requests without constructing a client.
# Tests: Posel::get, Posel::get_json, Posel::post_json, Odpowiedz methods,
#        header inspection, status classification.

import("../posel")

pokazl "=== 1. Podstawowy GET ==="
niech odp = Posel::get("https://jsonplaceholder.typicode.com/users/1")
pokazl odp.napis()
pokazl "Status: " + odp.status()
pokazl "Content-Type: " + odp.naglowek("Content-Type")
pokazl "Czy sukces: " + odp.czy_sukces()
pokazl "Body length: " + odp.cialo().dlg()

pokazl ""
pokazl "=== 2. GET JSON — sparsowane dane od razu ==="
niech user = Posel::get_json("https://jsonplaceholder.typicode.com/users/1")
pokazl "Imie: " + user["name"]
pokazl "Email: " + user["email"]
pokazl "Miasto: " + user["address"]["city"]

pokazl ""
pokazl "=== 3. POST JSON ==="
niech utworzony = Posel::post_json("https://jsonplaceholder.typicode.com/posts", {
  "title": "Test z posla",
  "body": "Treść testowa",
  "userId": 1
})
pokazl "Utworzony post ID: " + utworzony["id"]
pokazl "Tytul: " + utworzony["title"]

pokazl ""
pokazl "=== 4. Klasyfikacja statusu ==="
niech odp_404 = Posel::get("https://jsonplaceholder.typicode.com/users/99999", {
  "rzucaj_bledy": falsz
})
pokazl "Status: " + odp_404.status()
pokazl "Czy sukces: " + odp_404.czy_sukces()
pokazl "Czy blad klienta: " + odp_404.czy_blad_klienta()
pokazl "Czy blad serwera: " + odp_404.czy_blad_serwera()
pokazl "Czy blad: " + odp_404.czy_blad()

pokazl ""
pokazl "=== 5. Lazy JSON parsing — wywolanie wielokrotne, jeden parse ==="
niech odp_user = Posel::get("https://jsonplaceholder.typicode.com/users/2")
niech parsed_1 = odp_user.json()
niech parsed_2 = odp_user.json()
pokazl "Pierwsze .json() i drugie zwracaja te same dane: " + parsed_1["name"]
pokazl "Drugie wywolanie tez: " + parsed_2["name"]
