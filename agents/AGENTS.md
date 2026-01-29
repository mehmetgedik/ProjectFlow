## Agent çalışma modeli

Bu dosya, paralel geliştirmede görevlerin nasıl bölüneceğini ve kontrol mekanizmasını tanımlar.

### Roller

- **Main agent (senin ana agentin)**: kapsamı netleştirir, analiz formatını korur, riskleri toplar, entegrasyon noktalarını kontrol eder.
- **Implementer agent**: belirli bir epic/feature’ı uygular (teknik tasarım dahil).
- **API/Integration agent**: endpoint keşfi, sözleşme, pagination/filter, hata senaryoları.
- **UX/Flow agent**: ekran akışları, boş/yükleme/hata durumları, erişilebilirlik.
- **Reviewer agent**: değişiklikleri kalite/edge-case/güvenlik açısından denetler, sorunları `docs/reviews/` altına yazar.

### Görev paketleme standardı

Her agent’a verilen görev şu alanları içerir:

- **Scope**: hangi epic/feature + dahil/harici
- **Inputs**: ilgili analiz dokümanı(ları)
- **Output**: beklenen çıktı (kod + test + kısa özet)
- **Acceptance criteria**: analiz dokümanından aynen
- **Non-goals**: özellikle yapılmayacaklar

### Review standardı

Reviewer çıktısı şu formatta olmalı:

- **Finding**: sorun / risk
- **Impact**: kullanıcı / güvenlik / veri / performans etkisi
- **Recommendation**: düzeltme önerisi
- **Evidence**: dosya/ekran/endpoint referansı

