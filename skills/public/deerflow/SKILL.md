---
name: deerflow
description: Use when installing, configuring, or debugging DeerFlow 2.0 — local setup, LLM integration, auth/CSRF workarounds, and run testing.
---

# DeerFlow

## Ön Yüz Kuralları
- Yerel geliştirme için `DEER_FLOW_AUTH_DISABLED=*** kullan — bu hem auth'ı hem CSRF'yi devre dışı bırakır.
- NVIDIA NIM veya benzeri OpenAI-compatible sağlayıcılar için `base_url` ve `api_key` field'larını `config.yaml` içine yaz.
- Test mesajlarını tarayıcı arayüzünden gönder (http://localhost:2026) — curl ile CSRF token'ı almak için ekstra adımlar gerekir.

## Pitfall: CSRF Double-Submit Cookie Pattern
**curl ile local'den login yapma** — DeerFlow CSRF double-submit cookie pattern kullanır. CSRF token cookie'si olmadan auth endpoint'leri 403 döner. Çözüm:
1. `DEER_FLOW_AUTH_DISABLED=*** set et (`.env dosyasına ekle)
2. Servisi yeniden başlat: `make stop && make start`
3. Test için tarayıcı kullan veya API key ile çalış

## Pitfall: Browser Session Drops
Tarayıcı çağrıları arasında session sekmeleri düşebilir. Bunu önlemek için:
- Login + test mesajı gönderme + response kontrolünü **tek bir browser_exec çağrısında** yap
- `new_tab()` ile yeni sekme açtıktan hemen sonra `fill_input()` ve `js()` ile mesaj gönder
- Poll döngüsünü aynı çağrı içinde tut (12-14 poll, 5'şer saniye aralıklarla)

## Procedure: LLM Entegrasyonu (NVIDIA NIM Örneği)
1. API key'i `.env` dosyasına ekle:
   ```
   NVIDIA_API_KEY=nvapi-XXXXXXX
   ```
2. `config.yaml` içine model tanımla:
   ```yaml
   models:
     - name: glm-5.3
       display_name: GLM-5.3 (NVIDIA NIM)
       use: langchain_openai:ChatOpenAI
       model: z-ai/glm-5.3
       api_key: $NVIDIA_API_KEY
       base_url: https://integrate.api.nvidia.com/v1
       request_timeout: 600.0
       max_retries: 2
       max_tokens: 16384
       context_window: 131072
       temperature: 0.7
   ```
3. Servisleri yeniden başlat: `make stop && make start`
4. Tarayıcıdan test: http://localhost:2026 → yeni chat → mesaj gönder

## Procedure: Run Test (API ile)
1. Thread oluştur:
   ```bash
   curl -X POST http://localhost:2026/api/threads \
     -H "Content-Type: application/json" \
     -d '{"title":"Test Thread"}'
   ```
2. Run başlat:
   ```bash
   curl -X POST http://localhost:2026/api/threads/{thread_id}/runs \
     -H "Content-Type: application/json" \
     -d '{
       "input": {
         "messages": [
           {"type": "human", "data": {"content": "Test mesajı"}}
         ]
       }
     }'
   ```

## Process Management (Windows)
- Süreç temizleme: `taskkill /F /IM <process_name> /T`
- Uzun süren `make start` işlemlerinde timeout alırsan:
  1. `make stop` ile durdur
  2. `taskkill` ile kalan süreçleri temizle
  3. `make start` ile yeniden başlat (background=true ile çalıştır)
  4. `curl http://localhost:2026/` ile hazırlığı doğrula
