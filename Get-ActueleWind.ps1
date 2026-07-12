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

function Resolve-LocationCode {
    param (
        [Parameter(Mandatory)]
        [string]$StationCode
    )

    $stationCodeMap = @{
        '6225' = 'ijmuiden.buitenhaven'
    }

    if ($stationCodeMap.ContainsKey($StationCode)) {
        return $stationCodeMap[$StationCode]
    }

    return $StationCode
}

function Get-WaterinfoJson {
    param (
        [Parameter(Mandatory)]
        [string]$Uri
    )

    return Invoke-RestMethod -Uri $Uri -Method Get -Headers @{
        'User-Agent' = 'ActueleWind-Script/1.0'
        'Accept' = 'application/json'
    } -TimeoutSec 10
}

function Get-DirectionMeasurement {
    param (
        [Parameter(Mandatory)]
        [string]$LocationCode
    )

    $directionParameter = 'Windrichting___20in___20Lucht___20t.o.v.___20ware___20Noorden___20in___20graad'
    $uri = 'https://waterinfo.rws.nl/api/point/latestmeasurement?parameterId=wind'
    $data = Get-WaterinfoJson -Uri $uri
    $feature = $data.features | Where-Object { $_.properties.locationCode -eq $LocationCode } | Select-Object -First 1

    if (-not $feature) {
        return $null
    }

    return $feature.properties.measurements |
        Where-Object { $_.parameterId -eq $directionParameter } |
        Select-Object -First 1
}

$LocationCode = Resolve-LocationCode -StationCode $StationCode
$uri = "https://waterinfo.rws.nl/api/detail/get?locationCode=$([uri]::EscapeDataString($LocationCode))&mapType=wind"

try {
    $response = Get-WaterinfoJson -Uri $uri

    if (-not $response.latest) {
        throw "No current wind speed found for location '$LocationCode'."
    }

    $direction = Get-DirectionMeasurement -LocationCode $LocationCode
    $StationName = $response.location

    $Windsnelheid = Convert-MeterPerSecondToKnots -MetersPerSecond $response.latest.data
    $windrichtingGR = if ($direction) { $direction.latestValue } else { $null }

    $refreshSeconds = [int](($response.refreshSpeedInMs ?? 0) / 1000)

    $result = @{
        locatie  = $StationName
        windrichtingVan   = $null
        windrichtingTot = $null
        Windsnelheid = $Windsnelheid
        windrichtingGR = $windrichtingGR
        bron = 'Rijkswaterstaat Waterinfo'
        refreshSeconds = $refreshSeconds
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
