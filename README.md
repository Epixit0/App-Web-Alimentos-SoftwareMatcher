# App-Web-Alimentos-SoftwareMatcher (SourceAFIS)

Servicio HTTP para extraer templates y comparar huellas **sin** depender de DLLs del vendor.

## Endpoints

- `GET /health`
- `POST /api/template`
- `POST /api/verify`
- `POST /api/identify`

## Formatos soportados

### Raw grayscale (recomendado para este proyecto)

Como los lectores Futronic suelen entregar un frame crudo (grayscale) y no un PNG/JPEG, el API soporta:

- `RawGrayscaleBase64`: bytes crudos de la imagen (1 byte por pixel)
- `Width`, `Height`
- `Dpi` (opcional)

### Imagen codificada (PNG/JPEG)

También acepta `ImageBase64` (data-url o base64 puro).

## Config

- `SOURCEAFIS_THRESHOLD` (default `40`)

## Docker

```bash
docker build -t marcaribe-software-matcher .
docker run --rm -p 5100:5100 -e SOURCEAFIS_THRESHOLD=40 marcaribe-software-matcher
```
