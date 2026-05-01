# bledy.as — exception hierarchy for Posel.
# Root: BladPosla < BladWykonania. HTTP errors carry references to
# Odpowiedz and Zapytanie for full context inside zlap blocks.

modul Posel {

  klasa BladPosla < BladWykonania {
    funkcja konstruktor(k) { super(k) }
  }

  klasa BladSieci < BladPosla {
    funkcja konstruktor(k) { super(k) }
  }

  klasa BladTimeoutu < BladPosla {
    funkcja konstruktor(k) { super(k) }
  }

  klasa BladSerializacji < BladPosla {
    funkcja konstruktor(k) { super(k) }
  }

  klasa BladHttp < BladPosla {
    funkcja konstruktor(k, odpowiedz, zapytanie) {
      super(k)
      niech @odpowiedz = odpowiedz
      niech @zapytanie = zapytanie
    }

    funkcja odpowiedz() { zwroc @odpowiedz }
    funkcja zapytanie() { zwroc @zapytanie }

    funkcja status() {
      jesli @odpowiedz == nic to zwroc nic
      zwroc @odpowiedz.status()
    }
  }

  # 4xx
  klasa BladHttpKlienta < BladHttp {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  klasa BladZleZapytanie < BladHttpKlienta {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  klasa BladNieautoryzowany < BladHttpKlienta {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  klasa BladBrakDostepu < BladHttpKlienta {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  klasa BladNieZnaleziono < BladHttpKlienta {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  klasa BladKonfliktu < BladHttpKlienta {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  klasa BladPrzeciazenia < BladHttpKlienta {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  # 5xx
  klasa BladHttpSerwera < BladHttp {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  klasa BladWewnetrzny < BladHttpSerwera {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  klasa BladBramy < BladHttpSerwera {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  klasa BladNiedostepny < BladHttpSerwera {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }

  klasa BladTimeoutuBramy < BladHttpSerwera {
    funkcja konstruktor(k, o, z) { super(k, o, z) }
  }
}
