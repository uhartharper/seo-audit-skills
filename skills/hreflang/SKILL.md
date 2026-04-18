---
name: hreflang
description: >
  Implementación y auditoría de hreflang para sitios multilingües o multirregionales
  en WordPress. Cubre WPML, TranslatePress, Yoast SEO, implementación manual con HFCM,
  reciprocidad, x-default, errores comunes y validación. Usar cuando el sitio tenga
  versiones en varios idiomas o regiones, o cuando se detecten issues de hreflang
  en GSC o herramientas de auditoría.
user-invokable: false
---

# Hreflang — Guía Técnica SEO

> Especificación oficial: https://developers.google.com/search/docs/specialty/international/localization-with-hreflang

---

## Fundamentos de hreflang

### Qué hace hreflang

Indica a Google qué versión de una página mostrar a usuarios de cada idioma o región.
No afecta directamente al ranking — afecta a qué URL se muestra en cada SERP regional.

### Cuándo implementar

- Sitio con versiones en más de un idioma (es, en, fr...)
- Sitio con versiones para distintas regiones del mismo idioma (es-ES, es-MX, es-AR)
- Subdirectorios, subdominios o dominios diferentes por idioma/región

### Cuándo NO implementar

- Sitio traducido automáticamente sin revisión humana — Google puede penalizarlo
- Sitio con solo una versión de cada página sin equivalente real en otro idioma
- Traducciones parciales (<50% del sitio) sin plan de completar — genera más problemas que beneficios

---

## Sintaxis correcta

```html
<!-- En el <head> de CADA versión de la página -->
<link rel="alternate" hreflang="es" href="https://dominio.com/pagina/" />
<link rel="alternate" hreflang="en" href="https://dominio.com/en/page/" />
<link rel="alternate" hreflang="x-default" href="https://dominio.com/pagina/" />
```

### Reglas obligatorias

1. **Reciprocidad**: si A apunta a B, B debe apuntar a A. Sin reciprocidad, Google ignora el par.
2. **Self-reference**: cada página debe incluirse en su propio hreflang.
3. **URLs absolutas**: usar siempre URLs completas con protocolo y dominio.
4. **x-default**: URL a mostrar cuando ningún otro hreflang coincide con el usuario.
   Habitualmente es la versión principal del idioma más usado o la homepage.

### Códigos de idioma y región

| Formato | Ejemplo | Cuándo usar |
|---------|---------|-------------|
| Solo idioma | `hreflang="es"` | Una sola versión en español para todos |
| Idioma + región | `hreflang="es-ES"` | Versiones distintas para España vs México |
| Solo región | NO válido | No usar sin código de idioma |

---

## Implementación en WordPress

### Plugin WPML

WPML genera hreflang automáticamente si está correctamente configurado.

**Verificación:**
1. WPML > Configuración de idiomas > Hreflang: activado
2. Comprobar con WebFetch que los tags aparecen en `<head>`
3. Verificar que las URLs en los hreflang son las URLs canónicas (no con parámetros)

**Issue frecuente — hreflang no aparece en `<head>`:**
- WPML puede generar el hreflang en el body si hay conflicto con el theme o el page builder
- Verificar: View Source > buscar `rel="alternate"`
- Fix: WPML > Soporte > System Status para identificar conflictos

**Issue frecuente — página de prueba indexable (/idioma/home-2/):**
- Páginas de test creadas durante la configuración de WPML pueden quedar indexadas
- Detectar en Screaming Frog: URL contains "home-2" o similar
- Fix: noindex en Yoast + redirect 301 a la URL correcta

### TranslatePress

TranslatePress genera hreflang automáticamente.

**Conflicto con Yoast:**
Si Yoast también está configurado para generar hreflang, se generan dos bloques duplicados.
Desactivar en uno de los dos plugins — no en ambos.

**Desactivar en Yoast:**
SEO > Search Appearance > General > Hreflang: Off

### Yoast SEO (sin plugin de traducción)

Yoast puede gestionar hreflang para sitios con instalaciones WordPress independientes
por idioma (cada idioma en su propia instalación WP).

**Configuración:**
SEO > Search Appearance > General > Knowledge Graph > URL: asegurarse de que apunta
al dominio principal (no al subdirectorio).

**Issue: @id del WebSite incorrecto en instalación secundaria:**
La instalación del subdirectorio `/en/` puede generar `"@id": "https://dominio.com/en/#website"`
en lugar de `"https://dominio.com/#website"`.

Fix PHP en functions.php de la instalación secundaria:
```php
add_filter('wpseo_schema_website', function($data) {
    $data['@id'] = 'https://dominio.com/#website';
    $data['url'] = 'https://dominio.com/';
    return $data;
});
```

### Implementación manual con HFCM

Para sitios donde solo algunas páginas tienen equivalente en otro idioma
(traducción parcial), la implementación manual con HFCM es más segura que
usar un plugin en modo global.

**Cuándo usar HFCM:**
- <80% de páginas tienen equivalente en el otro idioma
- El plugin de traducción genera reciprocidad rota en páginas sin equivalente
- Se quiere control granular por página

**Setup:**
1. Instalar Header Footer Code Manager (HFCM)
2. New Snippet > tipo: Header
3. Pegar los tags hreflang correspondientes a esa página
4. Asignar: Pages > seleccionar solo las páginas con traducción confirmada

**Snippet ejemplo para homepage:**
```html
<link rel="alternate" hreflang="es" href="https://dominio.com/" />
<link rel="alternate" hreflang="en" href="https://dominio.com/en/" />
<link rel="alternate" hreflang="x-default" href="https://dominio.com/" />
```

---

## Errores comunes

### Error 1: Reciprocidad rota

**Síntoma en GSC:** "Alternate page with proper canonical tag" o páginas sin
impresiones en el idioma secundario.

**Causa:** La página A apunta a B en hreflang, pero B no tiene un hreflang apuntando
de vuelta a A.

**Casos frecuentes:**
- Plugin de hreflang global en sitio con traducción parcial
- URL de destino con redirect → la URL final no tiene hreflang coincidente
- La página en el otro idioma fue eliminada pero el hreflang no se actualizó

**Fix:** Auditar con Screaming Frog > Hreflang tab > columna "Missing Return Tag".

---

### Error 2: Hreflang a URL que devuelve 404 o redirect

**Síntoma en GSC:** "Return tag links to page that returns error" o warnings en
herramientas de auditoría.

**Causa:** Cambio de URL sin actualizar el hreflang, o página eliminada.

**Fix:**
- Si la URL cambió: actualizar el hreflang con la URL nueva
- Si la página fue eliminada: quitar el hreflang de las páginas que apuntaban a ella

---

### Error 3: hreflang en sitemap XML en lugar de en `<head>`

Google acepta hreflang en tres lugares: `<head>`, cabeceras HTTP, o sitemap XML.
El sitemap XML es más difícil de mantener en sincronía — cualquier cambio de URL
debe actualizarse en el sitemap hreflang manualmente o via plugin.

**Recomendación:** Priorizar implementación en `<head>` siempre que sea posible.

---

### Error 4: Código de idioma incorrecto

**Síntomas:** Google no reconoce el código → hreflang ignorado.

**Errores frecuentes:**
- `hreflang="es-sp"` → correcto: `hreflang="es-ES"`
- `hreflang="en-uk"` → correcto: `hreflang="en-GB"`
- `hreflang="cat"` → correcto: `hreflang="ca"` (catalán: código ISO 639-1)
- `hreflang="val"` → correcto: `hreflang="ca-ES"` (valenciano como variante regional del catalán)

---

### Error 5: x-default apuntando a URL incorrecta o ausente

**x-default** debe apuntar a la URL que debe mostrarse cuando ningún otro hreflang
coincide con el idioma/región del usuario.

**Errores:**
- x-default apuntando a una versión de idioma específica (ej: `/en/`) — debería
  apuntar a la página principal o a un selector de idioma
- x-default ausente — Google elige por su cuenta cuál mostrar

---

## Validación

### Screaming Frog — Hreflang Audit

Configuration > Spider > Crawl Linked XML Sitemaps → activar.

Tab Hreflang (en el crawl):
- **Noreturn**: URL referenciada que no tiene hreflang de vuelta → reciprocidad rota
- **Incorrect language code**: código de idioma no válido según ISO 639-1 / BCP 47
- **Non-canonical**: URL en hreflang que no es la canonical de esa página
- **Missing x-default**: no hay x-default declarado

### Google Search Console

Search Console > Internacional > Hreflang → muestra errores de implementación
detectados por Googlebot durante el crawl real.

**Errores comunes en GSC:**
- "Missing return tags" → reciprocidad rota
- "No return tag" → la URL referenciada no existe o no tiene hreflang de vuelta
- "URL in return tag not indexed" → la URL del otro idioma está noindex o desindexada

### Verificación manual rápida

```javascript
// Chrome DevTools > Console — ver todos los hreflang de la página actual
document.querySelectorAll('link[rel="alternate"]').forEach(l =>
  console.log(l.hreflang, l.href)
);
```

---

## Checklist de auditoría hreflang

```
CRÍTICO
[ ] ¿Reciprocidad completa? (A→B y B→A en todas las páginas)
[ ] ¿Self-reference presente en cada página?
[ ] ¿Las URLs en hreflang devuelven 200? (no 404 ni redirect)
[ ] ¿Las URLs son las canonicals? (no versión con parámetros ni redirect)

ALTO
[ ] ¿x-default presente y apuntando a URL correcta?
[ ] ¿Códigos de idioma válidos? (ISO 639-1 / BCP 47)
[ ] ¿URLs absolutas? (no relativas)
[ ] ¿Hreflang duplicado por dos plugins simultáneos?
[ ] ¿Páginas de test (home-2, draft, staging) con hreflang o indexables?

MEDIO
[ ] ¿Schema @id del WebSite apunta a URL raíz principal en todas las instalaciones?
[ ] ¿Hreflang presente en todas las páginas con equivalente, o solo en algunas?
[ ] GSC > Internacional: ¿errores activos reportados por Google?
[ ] ¿Plugin de hreflang en modo global con traducción parcial? → riesgo de reciprocidad rota

BAJO
[ ] ¿El sitemap XML declara hreflang o solo está en <head>?
[ ] ¿Hreflang en páginas noindex? (innecesario, puede confundir)
[ ] ¿Hreflang para páginas de utilidad (política de privacidad, aviso legal)?
   (opcional — bajo impacto)
```

---

## Referencias

- Hreflang spec Google: https://developers.google.com/search/docs/specialty/international/localization-with-hreflang
- Búsqueda internacional — guía completa: https://developers.google.com/search/docs/specialty/international
- GSC > Internacional: https://search.google.com/search-console/about
- Validador de códigos BCP 47: https://r12a.github.io/app-subtags/
