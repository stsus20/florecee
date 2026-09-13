# Florece

Aplicación móvil Flutter de cuidado de plantas, completamente local. Interfaz Material 3 en español inspirada en los cuatro mockups: crema, verdes botánicos, tarjetas redondeadas y acentos por cuidado. Las ilustraciones se dibujan con Canvas; no hay imágenes remotas ni capturas utilizadas como pantallas.

## Funciones
- Inicio con plantas, estado de revisiones, próximos cuidados y estadísticas.
- Crear, editar y eliminar con confirmación; catálogo de 15 especies.
- Cámara/galería opcional. Copia permanente de la imagen en documentos de la app.
- Guía de especie, historial de riego, abono, revisión, trasplante y sustrato húmedo.
- Posponer revisión 1–3 días. Revisar humedad no equivale a ordenar un riego.
- Calendario mensual, indicadores, filtros y cuidados completados.
- Programación manual de abono, revisión, riego orientativo y trasplante desde cada ficha.
- Notificaciones locales: permiso solicitado desde Inicio, zona IANA del dispositivo, alarmas inexactas y recuperación tras reinicio. Android puede retrasarlas por ahorro de energía. Los recordatorios vencidos siguen visibles en la app.
- Cuestionario de cuatro pasos con diez síntomas, nueve posibles causas y consultas guardadas.
- No hay backend, cuenta, reconocimiento de imágenes, clima ni servicios de nube. Copia automática Android desactivada.

## Estructura
- `lib/app.dart`: tema, arranque, navegación.
- `lib/screens/`: seis pantallas, formularios y ficha de especie.
- `lib/models/`: modelos, reglas de diagnóstico y cálculo de fechas.
- `lib/services/database_service.dart`: SQLite v1, claves externas, transacciones y punto de migraciones.
- `lib/services/app_store.dart`: estado y archivos de fotografía.
- `lib/services/notification_service.dart`: permisos y programación.
- `lib/widgets/`: tarjetas e ilustraciones botánicas.
- `lib/assets/data/catalogo_plantas.json`: catálogo incluido.
- `test/`: fechas, reglas, persistencia y pruebas de interfaz.

La base se crea vacía: no se insertan plantas del usuario ficticias. Los estados indican cumplimiento de revisiones, no certifican salud. El abono y trasplante se programan manualmente porque dependen de especie y temporada.

## Ejecutar en Android
Instala Android Studio y su SDK (Platform Tools, Build Tools y plataforma requerida por Flutter), configura un emulador o conecta un teléfono con depuración USB.
Si el SDK está en una ruta no detectada: `flutter config --android-sdk RUTA`.

```powershell
flutter doctor
flutter doctor --android-licenses
flutter pub get
flutter devices
flutter run -d ID_ANDROID
```

El SDK Android ya está instalado y se compila un APK release. No hay un teléfono conectado: cámara y entrega real de notificaciones siguen pendientes de comprobación en hardware. Esta versión utiliza SQLite móvil; no es una app web/Windows.

Los permisos, icono monocromático, receivers y desugaring están preparados en Android. No necesita claves API. Para distribución hay que configurar firma release propia: el proyecto conserva la firma debug del esqueleto original.

## Verificación
```powershell
flutter pub get
dart format .
flutter analyze
flutter test
```

Las pruebas SQLite usan `sqflite_common_ffi` únicamente como dependencia de desarrollo. Verifican cierre/reapertura, cuidado y posposición, unicidad de recordatorios y eliminación en cascada. La prueba de reapertura de base no reemplaza la comprobación de cierre y reapertura de la app en Android.

Pendiente en un Android real: instalar y abrir, crear planta con foto, cerrar/reabrir, probar cámara/galería y permisos denegados, recibir un recordatorio, editar/eliminar y comprobar su cancelación, reiniciar el teléfono. No se afirma que esa validación se haya realizado.

La configuración de notificaciones sigue la documentación de la versión instalada: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications).


Resultado de verificación (12 de septiembre de 2026): flutter pub get correcto; dart format . aplicado; flutter analyze sin incidencias; flutter test: 10 pruebas aprobadas. Pantallas principales probadas a 320 px con texto al 120 %.


## Actualización visual y de recordatorios
El icono original se conserva en `lib/assets/icon/app_icon.png`; el generador apunta a esa ruta. Android incorpora iconos por densidad y pantalla nativa de apertura crema. La apertura Flutter usa la ilustración con una transición de 650 ms y las entradas de contenido duran 340 ms; se respeta la reducción de movimiento del sistema. No se añadieron paquetes de animación.

Los permisos se consultan directamente al sistema al regresar de Ajustes, con estados separados para permiso denegado, canal bloqueado, fallo de inicialización y zona horaria. No se solicita otra vez un permiso ya concedido. Un fallo de zona no impide enviar una prueba inmediata. El botón «Probar notificación» envía un aviso al panel del teléfono; no confirma por sí mismo que el usuario lo haya visto. El canal conserva las preferencias del usuario y las alarmas siguen siendo inexactas.

La sincronización conserva avisos sin cambios, actualiza los modificados y cancela los eliminados. Los recursos del icono pequeño y de marca están protegidos del recorte de recursos release mediante `res/raw/keep.xml`.

Verificación actual: `dart format .`, `flutter analyze` sin incidencias y `flutter test` con 18 pruebas aprobadas. Compilación con `flutter build apk --release`. APK en `build/app/outputs/flutter-apk/app-release.apk`. Para actualizar el teléfono, instala el APK sobre la versión anterior y usa Inicio → Probar notificación. No se ha validado la entrega en un dispositivo físico conectado.
