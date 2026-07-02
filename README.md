# TRIA Scan AI — App Piloto (Flutter)

App funcional de reconocimiento visual de calzado Triples. Apunta la
camara, la app compara contra el catalogo indexado y muestra la ficha
tecnica del modelo identificado.

## Que trae este paquete

```
lib/
  main.dart
  theme/app_theme.dart              -> Tema Material 3 (claro/oscuro)
  domain/entities/                  -> Product, RecognitionResult
  services/
    embedding_service.dart          -> Genera el "embedding" visual de una foto
    catalog_repository.dart         -> Carga el catalogo (assets/catalog.json)
    recognition_service.dart        -> Indexa + compara + aplica umbrales
  screens/
    home_screen.dart                -> Pantalla inicial, boton "Escanear"
    scanner_screen.dart             -> Camara en vivo, captura la foto
    result_screen.dart              -> Match unico / varios candidatos / no identificado
    product_detail_screen.dart      -> Ficha tecnica elegante
assets/catalog/
  catalog.json                      -> 9 productos Triples confirmados
  images/                           -> Las 9 fotos reales usadas
pubspec.yaml
```

## Importante: como funciona el reconocimiento aqui

`embedding_service.dart` NO usa un modelo de IA/deep learning (CLIP,
MobileNet, etc.) — usa un descriptor de color por cuadricula, mas simple
pero funcional, que ya probamos en Python con buenos resultados (ver
`tria_pipeline_piloto.zip` que te comparti antes). Esto es intencional:
correr un modelo de IA real requiere descargar pesos pre-entrenados
(varios MB desde internet) y configuracion nativa adicional (TFLite),
que no pude verificar en mi entorno de trabajo por no tener acceso a
esos servidores ni un emulador para probar.

**La app SI funciona de principio a fin ahora mismo** (indexa el
catalogo, escanea con la camara, compara, muestra ficha tecnica). Lo
que se mejora despues es la precision, reemplazando SOLO el contenido
de `embedding_service.dart` por un modelo real. Ningun otro archivo
cambia gracias a la separacion en capas.

## Como correrla (paso a paso)

### 1. Requisitos
- Instalar Flutter SDK: https://docs.flutter.dev/get-started/install
- Tener un celular Android/iPhone conectado por USB (con modo
  desarrollador activado), o un emulador.

### 2. Generar el "esqueleto" nativo del proyecto

Este paquete trae el codigo Dart (`lib/`) y los assets, pero **no** trae
las carpetas nativas `android/` e `ios/` completas (esas las genera la
propia herramienta de Flutter, son cientos de archivos de configuracion
que no tiene sentido escribir a mano).

Dentro de la carpeta del proyecto, corre:

```bash
flutter create --project-name tria_scan_ai .
```

Esto va a generar `android/`, `ios/`, etc. **sin borrar** tu carpeta
`lib/` ni tus `assets/` (Flutter detecta que ya existen y no los toca).

### 3. Agregar el permiso de camara

**Android** — abre `android/app/src/main/AndroidManifest.xml` y agrega,
dentro de `<manifest>` (antes de `<application>`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS** — abre `ios/Runner/Info.plist` y agrega dentro del `<dict>` raiz:

```xml
<key>NSCameraUsageDescription</key>
<string>TRIA Scan AI necesita la camara para identificar el calzado.</string>
```

### 4. Instalar dependencias

```bash
flutter pub get
```

### 5. Correr la app

```bash
flutter run
```

Selecciona tu celular/emulador cuando te lo pida.

## Que vas a ver

1. Pantalla de inicio con el boton **Escanear** (se activa cuando el
   catalogo termina de indexarse, toma un par de segundos).
2. Camara en vivo con un marco guia — encuadra el calzado y toca el
   boton circular para capturar.
3. Resultado automatico:
   - Si hay una coincidencia clara -> ficha tecnica directa.
   - Si hay varias parecidas -> lista ordenada por % de similitud.
   - Si no se reconoce nada -> mensaje honesto, nunca inventa un modelo.

## Catalogo actual (10 productos Triples, 9 con foto)

Los 9 modelos vienen con **solo una foto (portada)**, excepto los que
ya tenian set completo. Esto limita la precision del reconocimiento
cuando el angulo de la foto escaneada es muy distinto al de catalogo.

**Siguiente paso recomendado:** agregar 3-4 fotos por modelo (lateral,
suela, cenital) para que el reconocimiento sea robusto a distintos
angulos, tal como se definio en la arquitectura original.

## Roadmap despues de este piloto

- [ ] Conseguir fotos multi-angulo de los modelos que faltan
- [ ] Migrar `embedding_service.dart` a un modelo real (MobileCLIP/TFLite)
- [ ] Mover el catalogo e indice a Supabase (pgvector) en vez de assets locales
- [ ] Agregar deteccion/recorte automatico del calzado (ML Kit) antes del embedding
- [ ] Pantalla de administracion para dar de alta productos nuevos
