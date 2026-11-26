#!/bin/sh
# uso: ./probar.sh <telefono> "<mensaje>"      (simula un mensaje de WhatsApp con el JSON de Meta)
#      ./probar.sh <telefono> --audio           (mensaje sin texto)
#      ./probar.sh --estado                     (aviso de "leído", sin mensaje)
#      ./probar.sh --invalido                   (JSON que no es de WhatsApp)
URL=http://localhost:5678/webhook/whatsapp-final
case "$1" in
  --estado) BODY='{"object":"whatsapp_business_account","entry":[{"changes":[{"field":"messages","value":{"messaging_product":"whatsapp","statuses":[{"id":"wamid.x","status":"read"}]}}]}]}';;
  --invalido) BODY='{"hola":"esto no es de WhatsApp"}';;
  *) BODY=$(PYTHONIOENCODING=utf-8 python - "$1" "$2" <<'PY'
import json,sys,time
tel,txt=sys.argv[1],sys.argv[2]
msg={"from":tel,"id":"wamid.prueba%d"%int(time.time()),"timestamp":str(int(time.time()))}
msg.update({"type":"audio","audio":{"id":"AUDIO_ID"}} if txt=="--audio" else {"type":"text","text":{"body":txt}})
print(json.dumps({"object":"whatsapp_business_account","entry":[{"id":"WABA_ID_PRUEBA","changes":[{"field":"messages","value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"15550001111","phone_number_id":"PHONE_ID_PRUEBA"},"contacts":[{"profile":{"name":"Seller de prueba"},"wa_id":tel}],"messages":[msg]}}]}]},ensure_ascii=False))
PY
);;
esac
printf '%s' "$BODY" > /tmp/final-msg.json
curl -s -w "\n[HTTP %{http_code} · %{time_total}s]\n" -X POST "$URL" -H "Content-Type: application/json" --data-binary @/tmp/final-msg.json
