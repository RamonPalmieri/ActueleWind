param
(
    $StationCode = '6225'
)

function Convert-MeterPerSecondToKnots {
    param (
        [Parameter(Mandatory)]
        [double]$MetersPerSecond
    )

    $knots = $MetersPerSecond * 1.94384449
    return [math]::Round($knots, 1, [MidpointRounding]::AwayFromZero)
}

<#
example response from /api/getSpotDetail.php?id=6210:
info     : @{stationcode=6210; stationnaam=Meetstation Katwijk; regio=Katwijk; latGraden=52.18; lonGraden=4.42;
             windrichtingVan=210; windrichtingTot=30; betrouwbaarheid=87; virtualspot=0}
winddata : {@{tijdstip=2026-05-31 17:20:00; windsnelheidMS=5.8; windstotenMS=8.2; windrichtingGR=263;
             windrichting=W; regenMMPU=; temperatuurGC=17.4; icoonactueel=Zwaar bewolkt}, ...}
#>

$uri = "https://actuelewind.nl/api/getSpotDetail.php?id=$StationCode"

try {
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{'User-Agent' = 'ActueleWind-Script/1.0'}

    $StationName = $response.info.stationnaam
    $windrichtingVan = $response.info.windrichtingVan
    $windrichtingTot = $response.info.windrichtingTot

    $LatestWindData = $response.winddata[0]

    $Windsnelheid = Convert-MeterPerSecondToKnots -MetersPerSecond $LatestWindData.windsnelheidMS
    $windrichtingGR = $LatestWindData.windrichtingGR

    $result = @{
        locatie  = $StationName
        windrichtingVan   = $windrichtingVan
        windrichtingTot = $windrichtingTot
        Windsnelheid = $Windsnelheid
        windrichtingGR = $windrichtingGR
    }

    return @{
        statusCode = 200
        body       = ($result | ConvertTo-Json -Depth 2)
        headers    = @{ "Content-Type" = "application/json" }
    }
}
catch {
    return @{
        statusCode = 500
        body       = "Error fetching/parsing wind data: $_"
    }
}