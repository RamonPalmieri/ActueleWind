<?php
#ini_set('display_errors', 1);
#error_reporting(E_ALL);

header('Content-Type: application/json');

function convertMeterPerSecondToKnots($mps) {
    $knots = $mps * 1.94384449;
    return round($knots, 1, PHP_ROUND_HALF_UP);
}

$stationCode = $_GET['station'] ?? '6225';

$uri = 'https://actuelewind.nl/getActualSpotData6.php';

    try {
        $json = file_get_contents($uri);

        if ($json === false || empty($json)) {
        throw new Exception("Could not fetch data or empty response.");
    }

    $data = json_decode($json, true);
    $spotData = $data['wind'][$stationCode];

    $stationName = $spotData['windspot']['stationnaam'];
    $windrichtingVan = $spotData['windspot']['windrichtingVan'];
    $windrichtingTot = $spotData['windspot']['windrichtingTot'];
    $latest = $spotData['winddata'][0];

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
}                                                                                            1,1           Top
