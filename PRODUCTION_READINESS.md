# OddsArbitrage — Camino a producción

Estado relevado el 2026-09-14. Repo `nicovma/OddsArbitrage`, público, `main`/`develop` protegidas (PR + CI obligatorio).

---

## 1. Bloqueantes duros (Apple rechaza el submit sin esto)

### 1.1 Privacy Manifest (`PrivacyInfo.xcprivacy`)
No existe en el proyecto. Obligatorio desde mayo 2024 para cualquier app que use APIs "required reason" (UserDefaults entra ahí — `BookmakerPreferencesStore` lo usa) o SDKs de terceros que lo requieran (Firebase Auth y GoogleSignIn ya traen su propio `PrivacyInfo.xcprivacy` embebido, pero el target de la app también necesita el suyo declarando el uso de `UserDefaults`).
- Agregar el archivo al target `OddsArbitrage`, declarar `NSPrivacyAccessedAPICategoryUserDefaults` con el reason code que corresponda (`CA92.1` — leer/escribir datos propios de la app).
- Verificar con `xcodebuild -showBuildSettings` / Xcode Organizer que no falte ningún manifest de las dependencias (Firebase, GoogleSignIn) al generar el archivo de App Store Connect.

### 1.2 Política de privacidad pública
La app pide login (email/password + Google) y guarda preferencias de usuario. App Store Connect exige una URL de política de privacidad antes de poder enviar a review.
- Redactar una página simple (qué datos se piden — email, preferencias de bookmakers —, que no se comparten con terceros más allá de Firebase/Google Auth).
- Publicarla en algún lado estable (GitHub Pages del propio repo, ya que es público, es la opción más barata).

### 1.3 Firebase/Google Sign-In de producción, separado del de desarrollo
`Info.plist` tiene el `GIDClientID` y el URL scheme hardcodeados, apuntando al proyecto Firebase actual (dev). Antes de submitir:
- Crear un Firebase project separado para prod (o al menos una app iOS separada dentro del mismo project, con su propio bundle ID de release si se usa un identificador distinto a debug).
- Regenerar `GoogleService-Info.plist` de prod y actualizar `GIDClientID`/`CFBundleURLSchemes` en `Info.plist` (hoy están fijos, no vienen de `Config.xcconfig` — conviene moverlos a un xcconfig por entorno para no pisarlos a mano en cada release).
- En Google Cloud Console, agregar el SHA/bundle de producción a los orígenes autorizados de Sign-In con Google.

### 1.4 App Icon y metadata de Store
El `AppIcon.appiconset` tiene una sola imagen (`AppIcon.png`) — confirmar que cubre todos los tamaños requeridos (el asset catalog moderno de Xcode 16 usa "single size" con escalado automático, pero hay que verificar que no falte el marketing icon de 1024×1024 para App Store Connect).
- Screenshots (6.9", 6.5", iPad si aplica), descripción, keywords, categoría, clasificación de edad.
- Nombre de la app en App Store Connect (verificar disponibilidad, "OddsArbitrage" puede chocar con trademarks de casas de apuestas — revisar antes de reservarlo).

---

## 2. Necesario para operar con usuarios reales (no bloquea el submit, pero rompe en producción)

### 2.1 Rate limit de The Odds API
El polling de `LiveOddsService` refresca cada 15s por usuario activo. El plan free de The Odds API da ~500 requests/mes total (no por usuario) — con un solo usuario probando 10 minutos ya se gastan ~40 requests.
- Pasar a un plan pago acorde al uso esperado, o
- Subir el intervalo de polling en prod (ej. 60s) y/o cachear server-side si en algún momento hay backend propio.
- Hoy no hay ningún manejo de "se acabó la cuota" distinto de un error genérico de red — el usuario vería un error de refresh sin explicación. Vale la pena mapear el 429 de la API a un mensaje específico.

### 2.2 Crash reporting / error tracking
No hay Crashlytics, Sentry ni nada equivalente en el proyecto. Ya se usa Firebase (Auth) así que Crashlytics es el camino de menor fricción:
- Agregar `FirebaseCrashlytics` al `Package.swift`/SPM, inicializarlo en `OddsArbitrageApp`.
- Sin esto, un crash en prod es invisible — te enterás por un review de 1 estrella, no por una alerta.

### 2.3 Analytics básico (opcional pero recomendado)
Ninguna instrumentación de producto (Firebase Analytics, o algo simple). No es bloqueante, pero sin esto no hay forma de saber si el arbitraje detectado se usa, si el login falla mucho, etc.

### 2.4 Manejo de secrets de release
Hoy `Config.xcconfig` y `GoogleService-Info.plist` se generan en CI desde GitHub Secrets solo para testing (`CODE_SIGNING_REQUIRED=NO`, ad-hoc). Para armar un `.ipa` firmado de release falta:
- Certificado de distribución + provisioning profile (o usar Xcode Cloud / fastlane con API key de App Store Connect).
- Un job de CI separado (`release.yml` o un step condicional) que solo corra en tags, firme con el certificate real, y suba a TestFlight — hoy `ci.yml` solo hace build-and-test.

### 2.5 Rotación de la API key actual
El `ODDS_API_KEY` que está en GitHub Secrets hoy es la de desarrollo. Si se reusa tal cual en prod, cualquier pico de tráfico real se come la cuota de testing y viceversa. Conviene tener key de dev y key de prod separadas desde ya, no como afterthought post-launch.

---

## 3. Recomendado, no bloqueante

- **Versionado real**: `MARKETING_VERSION` está en `1.0` fijo en el `.pbxproj`, `CURRENT_PROJECT_VERSION` en `1`. Definir una convención (semver + build number autoincremental) antes de la primera release, porque cambiarla después con usuarios ya instalados es más doloroso.
- **TestFlight con testers externos** antes del release público, al menos una ronda.
- **Accesibilidad**: no se relevó VoiceOver/Dynamic Type en este chequeo — vale una pasada rápida ya que Apple lo pondera en review discrecional.
- **Deep linking / Universal Links**: no existe hoy. No bloqueante si no hay flujo que lo necesite (ej. compartir un match), pero si se agrega después es más barato dejarlo pensado en la arquitectura de navegación ahora.
- **Localautomatización de release notes**: ya hay ES/EN en la UI (`Localizable.xcstrings`) — falta el mismo tratamiento para la descripción/release notes en App Store Connect.
- **Disclaimer legal**: la app calcula "arbitraje garantizado" entre casas de apuestas. Vale la pena un disclaimer explícito en la UI (no es asesoramiento financiero, las cuotas pueden cambiar antes de colocar la apuesta, restricciones legales de apuestas por jurisdicción) — reduce riesgo de rechazo en review y de reclamos de usuarios.

---

## 4. Orden sugerido de ejecución

1. Firebase/Google project de prod + xcconfig por entorno (2.4 depende de esto para poder firmar algo real).
2. Privacy manifest + política de privacidad pública (bloqueantes de submit, independientes de lo demás).
3. Crashlytics (barato de agregar, alto valor apenas hay usuarios reales).
4. Pipeline de release firmado (certificate, provisioning, job de CI a TestFlight).
5. Ajustar polling / manejo de rate limit antes de invitar testers externos.
6. Metadata de Store, screenshots, disclaimer legal, versionado — al final, cuando el build ya es estable.

## 5. Riesgos / dependencias externas

- Nombre "OddsArbitrage" en App Store: riesgo de rechazo o de objeción de terceros (casas de apuestas) por el uso del término "arbitrage" ligado a apuestas — confirmar antes de invertir tiempo en metadata definitiva.
- Apple Review puede objetar apps de apuestas/gambling-adjacent incluso sin dinero real involucrado (la app no coloca apuestas, solo informa cuotas) — vale revisar guideline 5.3 (Gaming, Gambling) antes del submit para no descubrirlo en un rechazo.
- The Odds API es una dependencia externa única (sin fallback) — si cambia de precio/deja de dar servicio, la app no tiene datos.
