# Feature: Zaman takibi hatırlatması (mesai bitimine yakın)

## Amaç

Kullanıcı, çalışma günü mesai bitimine yakın bir zamanda zaman takibi ile ilgili hatırlatma alabilsin; böylece gün sonunda zaman kaydını unutmasın.

## Kapsam

- Dahil:
  - Çalışma günlerinin OpenProject’ten (work schedule) alınması
  - Mesai bitimine yakın bir saatte (tek seferlik günlük hatırlatma) zaman takibi hatırlatması gösterilmesi
  - Hatırlatmanın yalnızca kullanıcı “bildirim göndersin” / “hatırlatma açık” dediği durumda gönderilmesi
  - Hatırlatmanın yalnızca çalışma günlerinde gösterilmesi
- Hariç:
  - Mesai başlangıç saati ile ilgili bildirim
  - Birden fazla hatırlatma zamanı seçimi (örn. sabah + akşam)

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak çalışma günümün sonuna yaklaşırken zaman kaydı hatırlatması almak istiyorum, böylece günü kapatmadan önce zamanımı gireyim.
- [ ] Kullanıcı olarak hatırlatmayı sadece bildirimleri açtığımda almak istiyorum.

## Kabul kriterleri

- [ ] Uygulama, OpenProject work schedule API’sinden haftalık çalışma günlerini (hangi günlerin working olduğu) alabilir.
- [ ] Hatırlatma, yalnızca OpenProject’e göre o gün “çalışma günü” ise planlanır.
- [ ] Hatırlatma, kullanıcı “zaman takibi hatırlatması”nı açtıysa ve bildirim izni verdiysa gösterilir.
- [ ] Hatırlatma metni zaman takibi ile ilgili olur (örn. “Bugünkü zaman kaydınızı girmeyi unutmayın”).
- [ ] Hatırlatma, mesai bitimine yakın tek bir zaman diliminde (örn. bitişten X dakika önce) gösterilir.
- [ ] Work schedule API erişilemez veya hata dönerse, uygulama makul bir varsayılanla (örn. hafta içi) çalışmaya devam edebilir veya hatırlatmayı o gün atlayabilir.

## İş kuralları

- Çalışma günü bilgisi OpenProject instance’ına göre belirlenir (haftalık tekrarlayan çalışma günleri).
- OpenProject API’de “günlük mesai saati” (başlangıç/bitiş) alanı yoktur; mesai bitiş saati uygulama varsayılanı veya kullanıcı tercihi ile belirlenir.
- Hatırlatma, yerel bildirim (local notification) ile gösterilir; sunucu tarafı push zorunlu değildir.

## Hata durumları

- Work schedule API 404/403/500: Varsayılan çalışma günleri kullanılır veya hatırlatma o gün atlanır.
- Kullanıcı bildirim iznini kapattıysa: Hatırlatma gösterilmez.
- Kullanıcı “zaman takibi hatırlatması”nı kapattıysa: Hatırlatma gösterilmez.

## Not (API sınırı)

OpenProject Work Schedule API’si yalnızca **çalışma günlerini** (haftanın hangi günleri working) verir; **günlük mesai saati aralığı** (başlangıç/bitiş saati) API’de yoktur. Bu nedenle “mesai bitiş saati” uygulama içi varsayılan (örn. 17:00) veya kullanıcı ayarı ile tanımlanmalıdır.
