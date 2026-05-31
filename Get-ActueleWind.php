<?php
#ini_set('display_errors', 1);
#error_reporting(E_ALL);

header('Content-Type: application/json');

function convertMeterPerSecondToKnots($mps) {
    $knots = $mps * 1.94384449;
    return round($knots, 1, PHP_ROUND_HALF_UP);
}

$stationCode = $_GET['station'] ?? '6225';

$uri = "https://actuelewind.nl/api/getSpotDetail.php?id={$stationCode}";

    try {
        $context = stream_context_create(['http' => ['header' => 'User-Agent: ActueleWind-Script/1.0']]);
        $json = file_get_contents($uri, false, $context);

        if ($json === false || empty($json)) {
        throw new Exception("Could not fetch data or empty response.");
    }

    $data = json_decode($json, true);

    $stationName = $data['info']['stationnaam'];
    $windrichtingVan = $data['info']['windrichtingVan'];
    $windrichtingTot = $data['info']['windrichtingTot'];
    $latest = $data['winddata'][0];

    $windsnelheid = convertMeterPerSecondToKnots($latest['windsnelheidMS']);
    $windstoten = convertMeterPerSecondToKnots($latest['windstotenMS']);
    $windrichtingGR = $latest['windrichtingGR'];

    $result = [
        "locatie" => $stationName,
        "windrichtingVan" => $windrichtingVan,
        "windrichtingTot" => $windrichtingTot,
        "Windsnelheid" => $windsnelheid,
        "Windstoten" => $windstoten,
        "windrichtingGR" => $windrichtingGR
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
