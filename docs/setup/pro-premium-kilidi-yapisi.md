# Pro premium kilidi – Yapı ve kullanım

Pro değilken özelliklerin nasıl kısıtlandığı ve kullanıcıda merak uyandırmak için kısıtlı özelliği gösterme (teaser) yapısı.

---

## Pro değilken ne olur?

Premium sayılan içerik **ProGate** ile sarılır. Pro **değilse**:

- **Tam kilit (varsayılan):** İçerik hiç gösterilmez; sadece "Bu özellik Pro sürümünde" mesajı + "Pro'ya yükselt" + "Satın almaları geri yükle" görünür.
- **Teaser (önizleme):** İçerik arkada **soluk** gösterilir; üzerinde yarı saydam katman + "Kullanmak için Pro'yu satın alın" + "Pro'yu satın al" / "Satın almaları geri yükle" olur. Kullanıcı özelliği görür ama kullanamaz; merak uyandırır.

Pro **varsa** her iki modda da içerik normal şekilde, kilit olmadan gösterilir.

---

## ProGate kullanımı

Aynı widget, iki kullanım:

| Parametre | Ne yapar | Ne zaman kullanılır |
|-----------|----------|----------------------|
| `showTeaser: false` (varsayılan) | Pro değilken sadece kilit mesajı + Yükselt / Geri yükle. İçerik görünmez. | Tamamen gizlenecek premium bölümler için. |
| `showTeaser: true` | Pro değilken içerik arkada soluk; üstte "Pro'yu satın al" katmanı. İçerik görünür ama tıklanamaz. | Kullanıcıya "ne kaçırdığını" göstermek, merak uyandırmak için. |

### Örnek – tam kilit

```dart
ProGate(
  message: 'Gelişmiş zaman raporu Pro sürümünde.',
  child: GelişmişZamanRaporuWidget(),
)
```

Pro değilken: sadece kilit ikonu + mesaj + "Pro'ya yükselt" / "Satın almaları geri yükle".

### Örnek – teaser (kısıtlı göster, kullanmak için Pro)

```dart
ProGate(
  showTeaser: true,
  message: 'Bu özellik Pro sürümünde. Kullanmak için Pro\'yu satın alın.',
  child: GelişmişZamanRaporuWidget(),
)
```

Pro değilken: aynı widget arkada soluk (opacity 0.4) görünür; üstte gradient + kilit + mesaj + "Pro'yu satın al" / "Satın almaları geri yükle". Kullanıcı özelliği görür, kullanmak için Pro’ya yönlendirilir.

---

## Hangi ekranlara / nereye uygulanır?

- **Hangi özelliklerin Pro olduğu** ayrı kapsamda tanımlanır (örn. gelişmiş time tracking, saved filters, ekler).
- O ekranı veya bölümü **ProGate** ile sararsınız:
  - Sadece kilit mesajı istiyorsanız: `ProGate(child: ...)` (showTeaser varsayılan false).
  - "Kısıtlı göster, kullanmak için Pro satın al" istiyorsanız: `ProGate(showTeaser: true, child: ...)`.

---

## Özet

- Pro **değilken** özellikler **ProGate** ile kısıtlanır: ya tam kilit (sadece Yükselt ekranı) ya teaser (içerik soluk + Pro satın al CTA).
- **Merak uyandırmak** için premium ekranlarda `showTeaser: true` kullanın; kullanıcı içeriği görür, kullanmak için "Pro'yu satın al" ile yönlendirilir.
- Pro **varsa** child her zaman normal gösterilir; kilit veya overlay yoktur.
