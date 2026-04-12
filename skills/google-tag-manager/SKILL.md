---
name: google-tag-manager
description: >
  Diagnóstico y configuración de Google Tag Manager. Casos de uso principales:
  evento GTM que no llega a GA4, dataLayer debugging, Consent Mode v2, firing order,
  Preview vs Production discrepancies. Aplica a todos los proyectos SEO donde se
  detecte GTM instalado.
user-invokable: false
---

# Google Tag Manager — Knowledge Base

## Casos de uso cubiertos

1. Evento GTM no se registra en GA4
2. Discrepancia Preview Mode vs Producción
3. dataLayer debugging
4. Consent Mode v2 bloqueando tags
5. Firing order: GA4 Configuration Tag vs Event Tags
6. Container instalado pero no disparando

---

## Diagnóstico: Evento que no llega a GA4

### Árbol de decisión (en orden)

```
1. ¿El tag está pausado?
   GTM UI > Tags > columna Status. Si aparece "Paused", reactivar.

2. ¿El trigger tiene condiciones demasiado restrictivas?
   Revisar Every Page vs Page URL contains vs Custom Event.
   Testear con trigger más amplio para aislar.

3. ¿Preview Mode confirma que el tag dispara?
   GTM > Preview > navegar al evento.
   Si aparece en "Tags Fired" → el problema está en GA4, no en GTM.
   Si NO aparece → el problema está en el trigger o en el dataLayer.

4. ¿Consent Mode v2 está bloqueando?
   Ver sección dedicada abajo.

5. ¿GA4 Configuration Tag disparó ANTES que el Event Tag?
   Ver sección Firing Order abajo.

6. ¿El Measurement ID es correcto?
   GA4 Config Tag > Measurement ID. Debe coincidir con el stream en GA4 Admin.

7. ¿El evento llega a GA4 pero no aparece en informes?
   Los eventos tardan 24-48h en informes estándar. Verificar en DebugView primero.
```

---

## Preview Mode vs Producción

### Diferencias clave

| Comportamiento | Preview Mode | Producción |
|---|---|---|
| Ad blockers | Bypasados | Bloquean si hay reglas para GTM |
| Consent Mode | Bypasado en versiones antiguas | Aplicado según consentimiento real |
| Cache del navegador | Versión de trabajo (no publicada) | Versión publicada |
| Extensiones del navegador | Pueden interferir | Ídem |

### Implicaciones diagnósticas

- Tag dispara en Preview pero NO en producción → **primer sospechoso: Consent Mode o ad blocker**.
- Tag NO dispara en Preview → el problema es del trigger o del dataLayer, no del entorno.
- Testear siempre Preview en incógnito para eliminar extensiones y cookies persistentes.
- Después de cambios en el container: refrescar Preview con el botón "Refresh" — la sesión de debug puede quedar obsoleta.

### Cómo forzar debug en producción

Añadir `?gtm_debug=x` a la URL. Equivale a Preview Mode pero en el entorno real (con ad blockers y consent activos).

---

## dataLayer

### Estructura básica

```javascript
// Push estándar
window.dataLayer = window.dataLayer || [];
dataLayer.push({
  'event': 'nombre_evento',
  'parametro1': 'valor1',
  'parametro2': 'valor2'
});
```

### Reglas de naming

- Los nombres de eventos en `dataLayer.push({'event': '...'})` deben coincidir **exactamente** con el nombre en el Custom Event Trigger de GTM (case-sensitive).
- Evitar espacios — usar guión bajo o camelCase.
- GA4 tiene eventos reservados que no se pueden usar como nombres personalizados: `click`, `view`, `scroll`, `session_start`, `first_visit`.

### Cómo verificar el dataLayer en consola

```javascript
// Ver el estado actual completo
console.log(dataLayer);

// Ver el último push
console.log(dataLayer[dataLayer.length - 1]);
```

En GTM Preview, pestaña "Data Layer" muestra todos los pushes en orden cronológico con sus valores.

### Variables de dataLayer en GTM

GTM UI > Variables > User-Defined Variables > Data Layer Variable.
- Layer Version: Version 2 (estándar moderno).
- Variable Name: coincide con la clave del objeto en el push.

---

## Consent Mode v2

### Contexto

Obligatorio desde marzo 2024 para sitios en el EEE. Si no está configurado, GA4 puede dejar de recibir datos de usuarios que rechazan cookies.

### Cómo bloquea los tags de GA4

Por defecto, GA4 tags respetan `analytics_storage`. Si el usuario rechaza:
- `analytics_storage: 'denied'` → GA4 Event Tags **no disparan** (o envían pings sin identificador de usuario).
- Si el tag tiene configuración Basic Consent Mode: espera al consentimiento para disparar.
- Si el tag tiene configuración Advanced Consent Mode: dispara sin cookies, envía datos modelados.

### Diagnóstico Consent Mode

1. En la consola del navegador, antes de aceptar cookies:
```javascript
// Ver el estado del consentimiento
console.log(window.dataLayer.filter(x => x[0] === 'consent'));
```

2. En GTM Preview, pestaña "Consent": muestra el estado de cada señal (`analytics_storage`, `ad_storage`, `functionality_storage`, etc.).

3. Si `analytics_storage: denied` y el tag no tiene la opción "Override consent settings" → el tag no disparará hasta que el usuario acepte.

### Configuración correcta en GTM

```
GA4 Configuration Tag:
  - Consent Settings > No additional consent required
  ó
  - Activar "Advanced Consent Mode" (envía pings modelados)

CMP (Consent Platform):
  - Debe hacer dataLayer.push con gtag('consent', 'update', {...}) al aceptar/rechazar
  - Timing: ANTES de que dispare el GA4 Configuration Tag
```

### Consent Mode implementado correctamente

```javascript
// Defaults (en el <head>, antes del snippet de GTM)
gtag('consent', 'default', {
  'analytics_storage': 'denied',
  'ad_storage': 'denied',
  'wait_for_update': 500
});

// Update tras aceptar (callback del CMP)
gtag('consent', 'update', {
  'analytics_storage': 'granted',
  'ad_storage': 'granted'
});
```

---

## Firing Order: GA4 Configuration Tag vs Event Tags

### El problema más común

GA4 Event Tags necesitan que el GA4 Configuration Tag haya disparado primero. Si el Event Tag dispara antes (o si la Configuration Tag no dispara en absoluto), el evento se pierde.

### Configuración correcta

| Tag | Trigger | Tag Sequencing |
|---|---|---|
| GA4 Configuration | Initialization - All Pages | Ninguno |
| GA4 Event | Custom Event / Click / etc. | "Fire a tag before" → GA4 Configuration Tag |

En GTM UI: Edit Tag > Advanced Settings > Tag Sequencing > Fire a tag before [tag name] fires.

### Por qué "Initialization - All Pages" para la Configuration Tag

El trigger "Initialization" dispara antes que "All Pages" / "Page View". Garantiza que el gtag esté disponible cuando lleguen los eventos de página.

Jerarquía de triggers (orden de disparo):
```
1. Consent Initialization
2. Initialization
3. Page View (DOM Not Ready)
4. DOM Ready
5. Window Loaded
6. Custom Events (cuando ocurren)
```

---

## Verificación en GA4 DebugView

Ruta: GA4 > Admin (columna Property) > DebugView

### Activar modo debug

**Opción 1 — GTM:** Añadir parámetro `debug_mode: true` en el GA4 Configuration Tag > Fields to Set.

**Opción 2 — URL:** Añadir `?_gl=debug` (no oficial, puede variar).

**Opción 3 — Chrome Extension:** "Google Analytics Debugger" — activa debug en toda la sesión.

### Qué confirma DebugView

- El evento llega a GA4 en tiempo real (< 1 minuto de latencia).
- Los parámetros del evento tienen los valores correctos.
- El `measurement_id` corresponde al stream correcto.

Si el evento aparece en DebugView pero no en informes → problema de definición de evento en GA4, no de tracking.

---

## Casos frecuentes en clientes PubliUp

### Container GTM instalado pero sin datos en GA4

1. Verificar que el snippet de GTM está en `<head>` (noscript en `<body>`).
2. En WordPress/Divi: algunos plugins de caché sirven HTML sin GTM si el snippet se añadió después de que el caché se generó. Purgar caché.
3. En PrestaShop: verificar que el hook `displayHeader` tiene el snippet (no solo `displayFooter`).

### Evento de formulario no llega a GA4

1. ¿El formulario hace submit tradicional (recarga de página) o AJAX?
   - Submit tradicional: usar trigger "Form Submission" con "Wait for Tags" y "Check Validation".
   - AJAX: el formulario no recarga la página, el trigger "Form Submission" no dispara. Necesita Custom Event via dataLayer.push en el callback de éxito.

2. En Elementor Forms: activar "Success Message" como indicador o usar el hook `elementor_pro/forms/new_record` para hacer push al dataLayer.

3. En Contact Form 7: evento `wpcf7mailsent` disponible como Custom Event.

```javascript
// Contact Form 7 → GTM
document.addEventListener('wpcf7mailsent', function(event) {
  dataLayer.push({
    'event': 'form_submit',
    'form_id': event.detail.contactFormId
  });
}, false);
```

### Click en enlace de teléfono/email no registrado

```javascript
// GTM: Click Trigger
Trigger Type: Click - Just Links
Wait for Tags: checked (500ms)
Check Validation: checked
Trigger fires on: Click URL - contains - tel: (o mailto:)
```

---

## Container Snippets — Verificación de instalación

### Verificar que GTM está cargando

En consola del navegador:
```javascript
// Confirma que el objeto GTM existe
console.log(typeof google_tag_manager);

// Ver todos los containers cargados
console.log(Object.keys(google_tag_manager));
// Devuelve algo como: ['GTM-XXXXXXX']
```

### Verificar con Network tab

DevTools > Network > filtrar por `gtm.js`. Debe devolver 200. Si devuelve 404 → el container ID es incorrecto o GTM está bloqueado.

---

## Referencias

- GTM Help: https://support.google.com/tagmanager
- Consent Mode v2: https://developers.google.com/tag-platform/security/guides/consent
- GA4 Measurement Protocol: https://developers.google.com/analytics/devguides/collection/protocol/ga4
- dataLayer spec: https://developers.google.com/tag-platform/tag-manager/web/datalayer
- GTM firing order: https://support.google.com/tagmanager/answer/6103696
