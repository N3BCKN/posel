# 02_klient_z_konfiguracja.as
#
# Configured Posel::Klient instance with base URL, default headers and params.
# Tests: Klient.nowy, base_url joining, default headers/params merging,
#        per-call overrides, runtime config mutation.

import("../posel")

pokazl "=== 1. Klient z bazowym URL ==="
niech api = Posel::Klient.nowy({
  "bazowy_url": "https://jsonplaceholder.typicode.com",
  "naglowki": {
    "Accept": "application/json",
    "User-Agent": "posel-example/1.0"
  },
  "limit_czasu": 10
})

niech user = api.get_json("/users/1")
pokazl "Pobrano: " + user["name"]

pokazl ""
pokazl "=== 2. Domyslne parametry query ==="
niech api2 = Posel::Klient.nowy({
  "bazowy_url": "https://jsonplaceholder.typicode.com",
  "parametry": { "_limit": "3" }
})
niech posty = api2.get_json("/posts")
pokazl "Liczba postow (powinno byc 3): " + posty.dlg()

pokazl ""
pokazl "=== 3. Per-call override scala sie z domyslnymi ==="
niech komentarze = api2.get_json("/comments", {
  "parametry": { "postId": "1" }
})
pokazl "Komentarze dla postu 1: " + komentarze.dlg()

pokazl ""
pokazl "=== 4. Per-call naglowki ==="
niech odp = api.get("/users/1", {
  "naglowki": { "X-Custom-Header": "test-value" }
})
pokazl "Status z custom headerem: " + odp.status()

pokazl ""
pokazl "=== 5. Mutacja konfiguracji w trakcie zycia klienta ==="
api.ustaw_naglowek_domyslny("X-Tracked", "yes")
api.ustaw_parametr_domyslny("_limit", "2")
niech odp_z_tracked = api.get("/posts")
pokazl "Status: " + odp_z_tracked.status()
niech parsed = odp_z_tracked.json()
pokazl "Liczba postow z nowym domyslnym _limit=2: " + parsed.dlg()

pokazl ""
pokazl "=== 6. Pelny URL ignoruje bazowy_url ==="
niech zewn = api.get("https://httpbin.org/get")
pokazl "Status z innego domeny: " + zewn.status()

pokazl ""
pokazl "=== 7. Wszystkie metody ==="
niech g = api.get("/posts/1")
pokazl "GET: " + g.status()

niech p = api.post("/posts", "{\"title\":\"x\"}", {
  "naglowki": { "Content-Type": "application/json" }
})
pokazl "POST: " + p.status()

niech pu = api.put("/posts/1", "{\"title\":\"updated\"}", {
  "naglowki": { "Content-Type": "application/json" }
})
pokazl "PUT: " + pu.status()

niech pa = api.patch("/posts/1", "{\"title\":\"patched\"}", {
  "naglowki": { "Content-Type": "application/json" }
})
pokazl "PATCH: " + pa.status()

niech d = api.delete("/posts/1")
pokazl "DELETE: " + d.status()

niech h = api.head("/posts/1")
pokazl "HEAD: " + h.status()
