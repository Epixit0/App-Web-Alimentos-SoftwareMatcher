using Microsoft.AspNetCore.Http.Json;
using SourceAFIS;

var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<JsonOptions>(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = null;
});

var app = builder.Build();

app.MapGet("/health", () => Results.Ok(new { ok = true, service = "sourceafis" }));

app.MapPost("/api/template", (TemplateRequest req) =>
{
    if (req == null)
        return Results.BadRequest(new { ok = false, message = "Body requerido" });

    try
    {
        var template = BuildTemplateFromImageOrRaw(
            req.ImageBase64,
            req.RawGrayscaleBase64,
            req.Width,
            req.Height,
            req.Dpi);

        var serialized = template.ToByteArray();

        return Results.Ok(new { ok = true, templateBase64 = Convert.ToBase64String(serialized) });
    }
    catch (ArgumentException ex)
    {
        return Results.BadRequest(new { ok = false, message = ex.Message });
    }
    catch (Exception ex)
    {
        return Results.Problem(title: "Error generando template", detail: ex.Message);
    }
});

app.MapPost("/api/verify", (VerifyRequest req) =>
{
    if (req == null)
        return Results.BadRequest(new { ok = false, message = "Body requerido" });

    try
    {
        var threshold = ReadThreshold(app.Configuration);

        var probe = LoadTemplateOrBuildFromImageOrRaw(
            req.ProbeTemplateBase64,
            req.ProbeImageBase64,
            req.ProbeRawGrayscaleBase64,
            req.ProbeWidth,
            req.ProbeHeight,
            req.ProbeDpi);

        var cand = LoadTemplateOrBuildFromImageOrRaw(
            req.CandidateTemplateBase64,
            req.CandidateImageBase64,
            req.CandidateRawGrayscaleBase64,
            req.CandidateWidth,
            req.CandidateHeight,
            req.CandidateDpi);

        if (probe is null || cand is null)
            return Results.BadRequest(new { ok = false, message = "Datos insuficientes para comparar" });

        var score = new FingerprintMatcher(probe).Match(cand);
        return Results.Ok(new { ok = true, matched = score >= threshold, score, threshold });
    }
    catch (Exception ex)
    {
        return Results.Problem(title: "Error verificando huella", detail: ex.Message);
    }
});

app.MapPost("/api/identify", (IdentifyRequest req) =>
{
    if (req == null)
        return Results.BadRequest(new { ok = false, message = "Body requerido" });

    try
    {
        var threshold = ReadThreshold(app.Configuration);

        if (string.IsNullOrWhiteSpace(req.ProbeTemplateBase64))
            return Results.BadRequest(new { ok = false, message = "ProbeTemplateBase64 requerido" });

        if (req.Candidates == null || req.Candidates.Count == 0)
            return Results.BadRequest(new { ok = false, message = "Candidates requerido" });

        var probeBytes = DecodeBase64(req.ProbeTemplateBase64);
        var probe = TryDeserializeTemplate(probeBytes);
        if (probe == null)
            return Results.BadRequest(new { ok = false, message = "No se pudo deserializar ProbeTemplateBase64" });

        string? bestId = null;
        double bestScore = double.NegativeInfinity;

        foreach (var c in req.Candidates)
        {
            if (c == null || string.IsNullOrWhiteSpace(c.Id) || string.IsNullOrWhiteSpace(c.TemplateBase64))
                continue;

            var candBytes = DecodeBase64(c.TemplateBase64);
            var cand = TryDeserializeTemplate(candBytes);
            if (cand == null)
                continue;

            var score = new FingerprintMatcher(probe).Match(cand);
            if (score > bestScore)
            {
                bestScore = score;
                bestId = c.Id;
            }

            if (score >= threshold)
                return Results.Ok(new { ok = true, matched = true, workerId = c.Id, score, threshold });
        }

        return Results.Ok(new { ok = true, matched = false, workerId = bestId, score = bestScore, threshold });
    }
    catch (Exception ex)
    {
        return Results.Problem(title: "Error identificando huella", detail: ex.Message);
    }
});

app.Run();

static byte[] DecodeBase64(string? b64)
{
    if (string.IsNullOrWhiteSpace(b64))
        return Array.Empty<byte>();

    var comma = b64.IndexOf(',');
    if (comma >= 0 && b64[..comma].Contains("base64", StringComparison.OrdinalIgnoreCase))
        b64 = b64[(comma + 1)..];

    try { return Convert.FromBase64String(b64); }
    catch { return Array.Empty<byte>(); }
}

static double ReadThreshold(IConfiguration config)
{
    var raw = config["SOURCEAFIS_THRESHOLD"];
    if (double.TryParse(raw, out var v) && v > 0) return v;
    return 40;
}

static FingerprintTemplate? TryDeserializeTemplate(byte[] templateBytes)
{
    if (templateBytes == null || templateBytes.Length == 0)
        return null;

    try { return new FingerprintTemplate(templateBytes); }
    catch { return null; }
}

static FingerprintTemplate? LoadTemplateOrBuildFromImageOrRaw(
    string? templateBase64,
    string? imageBase64,
    string? rawGrayscaleBase64,
    int? width,
    int? height,
    int? dpi)
{
    if (!string.IsNullOrWhiteSpace(templateBase64))
    {
        var bytes = DecodeBase64(templateBase64);
        var tpl = TryDeserializeTemplate(bytes);
        if (tpl != null) return tpl;
    }

    try
    {
        return BuildTemplateFromImageOrRaw(imageBase64, rawGrayscaleBase64, width, height, dpi);
    }
    catch
    {
        return null;
    }
}

static FingerprintTemplate BuildTemplateFromImageOrRaw(
    string? imageBase64,
    string? rawGrayscaleBase64,
    int? width,
    int? height,
    int? dpi)
{
    // Prefer raw grayscale (más directo para frames crudos de lectores)
    if (!string.IsNullOrWhiteSpace(rawGrayscaleBase64))
    {
        if (width is not > 0 || height is not > 0)
            throw new ArgumentException("Para RawGrayscaleBase64 se requiere Width y Height");

        var raw = DecodeBase64(rawGrayscaleBase64);
        if (raw.Length == 0)
            throw new ArgumentException("RawGrayscaleBase64 inválido o vacío");

        var expected = checked(width.Value * height.Value);
        if (raw.Length != expected)
            throw new ArgumentException($"RawGrayscaleBase64 tiene {raw.Length} bytes, pero se esperaban {expected} (Width*Height)");

        var options = new FingerprintImageOptions { Dpi = dpi ?? 500 };
        var image = new FingerprintImage(width.Value, height.Value, raw, options);
        return new FingerprintTemplate(image);
    }

    if (!string.IsNullOrWhiteSpace(imageBase64))
    {
        var bytes = DecodeBase64(imageBase64);
        if (bytes.Length == 0)
            throw new ArgumentException("ImageBase64 inválido o vacío");

        var options = new FingerprintImageOptions { Dpi = dpi ?? 500 };
        var image = new FingerprintImage(bytes, options);
        return new FingerprintTemplate(image);
    }

    throw new ArgumentException("Debe enviar RawGrayscaleBase64+Width+Height o ImageBase64");
}

record TemplateRequest(
    string? ImageBase64,
    string? RawGrayscaleBase64,
    int? Width,
    int? Height,
    int? Dpi
);

record VerifyRequest(
    string? ProbeTemplateBase64,
    string? CandidateTemplateBase64,

    string? ProbeImageBase64,
    string? CandidateImageBase64,

    string? ProbeRawGrayscaleBase64,
    int? ProbeWidth,
    int? ProbeHeight,
    int? ProbeDpi,

    string? CandidateRawGrayscaleBase64,
    int? CandidateWidth,
    int? CandidateHeight,
    int? CandidateDpi
);

record IdentifyCandidate(string Id, string TemplateBase64);
record IdentifyRequest(string ProbeTemplateBase64, List<IdentifyCandidate> Candidates);
