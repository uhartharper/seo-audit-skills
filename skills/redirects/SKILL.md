---
name: redirects
description: >
  Auditoría e implementación de redirects 301/302 para SEO. Cubre cadenas y loops,
  migración de URLs, implementación en WordPress (plugins, .htaccess, Nginx),
  PrestaShop, detección con Screaming Frog, transmisión de PageRank, redirects
  temporales mal usados y checklist de migración completa.
user-invokable: false
---

# Redirects — Guía Técnica SEO

---

## Tipos de redirect y cuándo usar cada uno

| Código | Tipo | Transmite PageRank | Uso correcto |
|--------|------|--------------------|--------------|
| 301 | Moved Permanently | Sí (~99%) | Cambio de URL permanente, migración, HTTPS, www |
| 302 | Found (Temporary) | No garantizado | Redirección temporal, A/B testing, mantenimiento breve |
| 307 | Temporary Redirect | No | Como 302 pero respeta el método HTTP (POST→POST) |
| 308 | Permanent Redirect | Sí | Como 301 pero respeta el método HTTP |
| Meta refresh | — | No | Nunca para SEO — Google lo interpreta como 302 suave |
| JS redirect | — | No garantizado | Evitar para URLs indexables — Google puede no seguirlo |

**Regla práctica:** para SEO, usar 301 para cambios permanentes. Cualquier redirect
con historia de >3 meses debe convertirse en 301 si no lo es ya.

---

## Redirect chains y loops

### Redirect chain (cadena)

```
/url-a/ → 301 → /url-b/ → 301 → /url-c/
```

Google sigue cadenas de hasta ~5 saltos pero depreca la transmisión de PageRank en
cada salto. Los crawlers (Screaming Frog, Google) cuentan cada URL en la cadena
como un crawl separado — agota crawl budget en sitios grandes.

**Fix:** hacer que `/url-a/` apunte directamente a `/url-c/`.

**Causa frecuente de cadenas:**
- Migración de HTTP→HTTPS sin actualizar links internos: `http://` → `https://` → `/nueva-url/`
- Cambio de www a non-www combinado con otro redirect
- Múltiples migraciones sucesivas sin limpiar la capa anterior

### Redirect loop (bucle)

```
/url-a/ → 301 → /url-b/ → 301 → /url-a/
```

El browser y los crawlers abortan tras detectar el bucle. La página es inaccesible.

**Causa frecuente:**
- Reglas de .htaccess mal escritas que se aplican a la URL de destino
- Plugin de redirect que creó una regla inversa por error
- Migración de dominio con redirect bidireccional mal configurado

**Detección inmediata:**
```bash
curl -I -L --max-redirs 5 https://dominio.com/url-problemática/
# Si termina en "Maximum (5) redirects followed" → loop o cadena larga
```

---

## Implementación en WordPress

### Plugin Redirection (recomendado para gestión editorial)

- Permite crear/editar 301s desde el panel sin acceso a servidor
- Registra 404s automáticamente — ideal para detectar URLs rotas tras migración
- Almacena redirects en base de datos: más lento que .htaccess pero manejable

**Estructura:** Redirection > Add New:
- Source URL: `/url-origen/` (sin dominio)
- Target URL: `https://dominio.com/url-destino/` (absoluta para cross-domain)
- Type: 301

**Limitación:** los redirects del plugin se procesan vía PHP — añaden ~50-100ms de
latencia vs redirects a nivel servidor. Para sitios con cientos de redirects activos,
migrar los más importantes a .htaccess o Nginx.

### .htaccess (Apache)

```apache
# Redirect individual — más específico, mayor prioridad
Redirect 301 /url-origen/ https://dominio.com/url-destino/

# Redirect con RegEx — para patrones de URL
RewriteEngine On
RewriteRule ^categoria/producto-(.*)$ /nueva-categoria/$1 [R=301,L]

# HTTP → HTTPS (si no está en el servidor)
RewriteCond %{HTTPS} off
RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]

# www → non-www
RewriteCond %{HTTP_HOST} ^www\.dominio\.com$ [NC]
RewriteRule ^ https://dominio.com%{REQUEST_URI} [R=301,L]
```

**Orden de prioridad en .htaccess:** las reglas se evalúan de arriba a abajo.
Una regla general al principio puede capturar URLs que una regla específica más
abajo debería manejar de forma diferente.

### Nginx

```nginx
# Redirect individual
location = /url-origen/ {
    return 301 https://dominio.com/url-destino/;
}

# Redirect con capture group
location ~ ^/categoria/producto-(.*)$ {
    return 301 /nueva-categoria/$1;
}

# www → non-www
server {
    listen 80;
    server_name www.dominio.com;
    return 301 https://dominio.com$request_uri;
}
```

Los redirects en Nginx se procesan antes de PHP — la forma más eficiente.

### WordPress multisite y subdirectorios

En multisite con subdirectorios, los redirects del subsite deben respetar la base:
```apache
# Correcto: redirige dentro del subsite
Redirect 301 /es/url-origen/ /es/url-destino/

# Incorrecto: pierde el prefijo del subsite
Redirect 301 /url-origen/ /url-destino/
```

---

## Implementación en PrestaShop

### Redirects manuales — Tráfico > Redirecciones SEO & URLs

PrestaShop incluye una tabla de redirects en el panel de administración:
- Tipo: 301 o 302
- URL de origen (ruta relativa sin dominio)
- URL de destino

**Limitación:** solo acepta rutas relativas en el origen. Para redirects cross-domain
(cambio de dominio), usar .htaccess o Nginx.

### Friendly URLs y cambio de estructura de URLs

Cuando se activa "Friendly URLs" o se modifica la estructura en PrestaShop >
Preferencias > SEO & URLs:

1. PrestaShop regenera automáticamente las URLs de productos y categorías
2. Las URLs antiguas devuelven 404 a menos que se configuren redirects
3. Usar el módulo "Redirect SEO 301" o configurar .htaccess manualmente

**Issue frecuente — cambio del separador de categoría:**
Si el separador entre categoría y producto cambia (`/categoria_producto/` → `/categoria/producto/`),
todas las URLs de producto necesitan redirect. Generar el mapeo desde la tabla
`ps_product_lang` y `ps_category_lang` en la BD.

---

## Transmisión de PageRank

Los 301s transmiten ~99% del PageRank según la posición actual de Google. La "pérdida"
histórica del 15% ya no aplica desde la actualización de 2016.

**Implicación práctica:** una cadena de 3 redirects transmite el PageRank casi sin
pérdida si todos son 301. El argumento de "consolidar cadenas para no perder PageRank"
sigue siendo válido por crawl budget y latencia, no por transmisión de señales.

**302 y PageRank:**
Google puede tratar 302s de larga duración como 301s (entiende que la redirección
es "permanente en la práctica"). Sin embargo, no hay garantía — cualquier redirect
permanente debe ser 301 explícito.

---

## Migración completa de URLs

### Proceso recomendado

1. **Rastreo pre-migración**: Screaming Frog sobre el sitio actual. Exportar todas
   las URLs indexables con sus datos (title, H1, canonical, inlinks count).

2. **Mapeo de URLs**: crear un CSV con dos columnas: URL_ORIGEN → URL_DESTINO.
   - Priorizar por volumen de inlinks (URLs con más inlinks primero)
   - Mapear por similaridad de contenido, no solo por estructura de URL
   - Las URLs sin equivalente real → 301 a la categoría/sección más relevante,
     no a la homepage (redirect a homepage es señal pobre para Google)

3. **Implementar redirects** antes del lanzamiento del nuevo sitio.

4. **Validar redirects** antes del go-live:
   ```bash
   # Verificar batch con curl (ejemplo para lista de URLs)
   while IFS= read -r url; do
     echo "$url → $(curl -s -o /dev/null -w "%{http_code} %{redirect_url}" "$url")"
   done < urls_origen.txt
   ```

5. **Actualizar links internos**: una vez migrado, actualizar los links internos
   para apuntar a las URLs nuevas directamente. Los redirects internos son cadena
   innecesaria.

6. **Actualizar sitemap**: el sitemap debe contener solo las URLs nuevas (destino).
   Un sitemap con URLs que redirigen es señal contradictoria.

7. **Actualizar canonical**: verificar que los canonicals apuntan a URLs nuevas,
   no a URLs que redirigen.

8. **GSC: change of address** (si es migración de dominio):
   GSC > Configuración > Cambio de dirección — notifica a Google formalmente.

9. **Monitorizar GSC durante 3-4 semanas**: Coverage report — las URLs antiguas
   deben pasar de "Indexed" a "Redirect" progresivamente.

---

## Redirects y crawl budget

En sitios grandes (+10.000 URLs indexables), las cadenas de redirects consumen
crawl budget innecesariamente. Cada URL en la cadena es un request HTTP separado
que Googlebot debe hacer.

**Señal de problema:** GSC > Configuración > Estadísticas de rastreo muestra
un alto porcentaje de "redirecciones" en los requests. Normalmente debe ser <5%.

**Acción:** Screaming Frog > Response Codes > Redirection (3xx) — exportar y
limpiar cadenas, actualizando los links internos que apuntan a URLs intermedias.

---

## Casos especiales

### HTTPS y www — orden correcto de redirects

La cadena correcta para un sitio que migra a HTTPS y non-www:
```
http://www.dominio.com/ruta/ → https://dominio.com/ruta/  (1 solo salto)
```

La cadena incorrecta (genera 2 saltos):
```
http://www.dominio.com/ruta/ → https://www.dominio.com/ruta/ → https://dominio.com/ruta/
```

Verificar que las reglas de www y HTTPS se consolidan en un solo redirect.

### Soft 404 vs redirect

Una URL que devuelve 200 con contenido de "página no encontrada" es un soft 404.
Google puede tratarla como duplicate content. Si una URL ya no tiene contenido
válido: 301 a la URL más relevante, o 410 (Gone) si no hay equivalente.

### Redirect a homepage como fallback

Un redirect 301 a la homepage para URLs sin equivalente real es señal débil:
Google puede interpretarlo como "esta URL no tiene contenido propio" y deprecar
los links que apuntaban a ella. Redirigir a la sección o categoría más relevante
siempre es mejor.

---

## Detección con Screaming Frog

**Rastrear redirects:**
Configuration > Spider > Crawl linked XML sitemaps + Follow Internal Redirects: activar.

**Columnas clave:**

| Filtro/Tab | Qué detecta |
|------------|-------------|
| Response Codes > Redirection (3xx) | Todas las URLs que redirigen |
| Reports > Redirect Chains | Cadenas de 2+ saltos |
| Reports > Redirect Loops | Bucles detectados |
| Bulk Export > All Inlinks to Redirects | Links internos apuntando a URLs redirigidas |
| Sitemaps > URLs in Sitemap Redirecting | URLs del sitemap que son redirects |

**Workflow post-migración:**
1. Crawl del sitio nuevo
2. Reports > Redirect Chains → limpiar
3. Bulk Export > All Inlinks to Redirects → actualizar links internos
4. Sitemaps > URLs in Sitemap Redirecting → actualizar sitemap

---

## Checklist de auditoría de redirects

```
CRÍTICO
[ ] ¿Redirect loops detectados? (Screaming Frog > Reports > Redirect Loops)
[ ] ¿URLs importantes (homepage, categorías principales) devuelven 200 directo?
[ ] ¿Versión HTTP y HTTPS consolidadas en un solo redirect?
[ ] ¿www y non-www consolidados en un solo redirect?
[ ] ¿HTTP+www → HTTPS+non-www en un solo salto (no dos)?

ALTO
[ ] ¿Cadenas de redirect de 2+ saltos? (Reports > Redirect Chains)
[ ] ¿Links internos apuntando a URLs que redirigen? (Bulk Export > All Inlinks to Redirects)
[ ] ¿URLs del sitemap que son redirects? (Sitemaps > URLs in Sitemap Redirecting)
[ ] ¿302s que llevan más de 3 meses activos? → convertir a 301
[ ] ¿Redirects a homepage para URLs sin equivalente real?

MEDIO
[ ] ¿Canonicals apuntando a URLs que redirigen?
[ ] ¿Hreflang apuntando a URLs que redirigen?
[ ] En migraciones: ¿mapeo de URLs documentado y verificado?
[ ] ¿GSC > Estadísticas de rastreo: % de redirects < 5%?

BAJO
[ ] ¿Redirects gestionados por plugin PHP en lugar de .htaccess/Nginx? → valorar migrar
[ ] ¿Redirects de JS o meta refresh en páginas indexables?
[ ] ¿GSC > Cambio de dirección notificado para migraciones de dominio?
```

---

## Referencias

- Redirecciones y Google: https://developers.google.com/search/docs/crawling-indexing/301-redirects
- Migración de sitio: https://developers.google.com/search/docs/crawling-indexing/site-move-with-url-changes
- Cambio de dirección GSC: https://support.google.com/webmasters/answer/9370220
