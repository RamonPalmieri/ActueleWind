<?php
#ini_set('display_errors', 1);
#error_reporting(E_ALL);

header('Content-Type: application/json');

function convertMeterPerSecondToKnots($mps) {
    $knots = $mps * 1.94384449;
    return round($knots, 1, PHP_ROUND_HALF_UP);
}

function resolveLocationCode($stationCode) {
    $stationCodeMap = [
        "6225" => "ijmuiden.buitenhaven",
    ];

    $stationCode = trim((string)$stationCode);
    return $stationCodeMap[$stationCode] ?? $stationCode;
}

function fetchJson($uri) {
    $context = stream_context_create([
        'http' => [
            'header' => "User-Agent: ActueleWind-Script/1.0\r\nAccept: application/json\r\n",
            'timeout' => 10,
        ],
    ]);
    $json = file_get_contents($uri, false, $context);

    if ($json === false || empty($json)) {
        throw new Exception("Could not fetch data or empty response.");
    }

    $data = json_decode($json, true);
    if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception("Could not parse JSON response: " . json_last_error_msg());
    }

    return $data;
}

function getDirectionMeasurement($locationCode) {
    $directionParameter = "Windrichting___20in___20Lucht___20t.o.v.___20ware___20Noorden___20in___20graad";
    $uri = "https://waterinfo.rws.nl/api/point/latestmeasurement?parameterId=wind";
    $data = fetchJson($uri);

    foreach (($data['features'] ?? []) as $feature) {
        $properties = $feature['properties'] ?? [];
        if (($properties['locationCode'] ?? null) !== $locationCode) {
            continue;
        }

        foreach (($properties['measurements'] ?? []) as $measurement) {
            if (($measurement['parameterId'] ?? null) === $directionParameter) {
                return $measurement;
            }
        }
    }

    return null;
}

$stationCode = $_GET['station'] ?? '6225';
$locationCode = resolveLocationCode($stationCode);

$uri = "https://waterinfo.rws.nl/api/detail/get?locationCode=" . rawurlencode($locationCode) . "&mapType=wind";

try {
    $data = fetchJson($uri);
    $latest = $data['latest'] ?? null;
    if (!$latest) {
        throw new Exception("No current wind speed found for location '{$locationCode}'.");
    }

    $direction = getDirectionMeasurement($locationCode);
    $stationName = $data['location'];
    $windsnelheid = convertMeterPerSecondToKnots($latest['data']);
    $windrichtingGR = $direction['latestValue'] ?? null;

    $result = [
        "locatie" => $stationName,
        "windrichtingVan" => null,
        "windrichtingTot" => null,
        "Windsnelheid" => $windsnelheid,
        "windrichtingGR" => $windrichtingGR,
        "bron" => "Rijkswaterstaat Waterinfo",
        "refreshSeconds" => (int)(($data['refreshSpeedInMs'] ?? 0) / 1000)
    ];

    echo json_encode([
        "statusCode" => 200,
        "body" => $result
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode([
        "statusCode" => 500,
        "body" => "Error fetching/parsing wind data: " . $e->getMessage()
    ]);
}
