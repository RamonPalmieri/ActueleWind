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
example:
windspot    : @{stationcode=6210; stationnaam=Meetstation Katwijk; regio=Katwijk; latGraden=52.18; lonGraden=4.42; windgurucode=48303; windfindercode=katwijk_aan_zee; bannerImg=; virtualspot=1; 
              bannerUrl=; windrichtingVan=210; windrichtingTot=30}
regen       : 1
zon_opkomst : 05:22
zon_onder   : 22:00
winddata    : {@{tijdstip=2025-06-08 11:00:04; stationcode=6210; temperatuurGC=13.20; windsnelheidMS=8.8; windstotenMS=12.9; windrichtingGR=284.0; windrichting=WNW; regenMMPU=0.00; icoonactueel=Zwaar 
              bewolkt}, @{tijdstip=2025-06-08 10:50:03; stationcode=6210; temperatuurGC=12.90; windsnelheidMS=8.1; windstotenMS=10.9; windrichtingGR=284.0; windrichting=WNW; regenMMPU=0.00; 
              icoonactueel=Zwaar bewolkt en regen}, @{tijdstip=2025-06-08 10:40:03; stationcode=6210; temperatuurGC=12.90; windsnelheidMS=8.1; windstotenMS=10.9; windrichtingGR=284.0; windrichting=WNW; 
              regenMMPU=0.00; icoonactueel=Zwaar bewolkt en regen}, @{tijdstip=2025-06-08 10:30:02; stationcode=6210; temperatuurGC=12.80; windsnelheidMS=5.4; windstotenMS=10.3; windrichtingGR=285.0; 
              windrichting=WNW; regenMMPU=0.00; icoonactueel=Zwaar bewolkt en regen}…}
#>

$uri = "https://actuelewind.nl/getActualSpotData6.php"

try {
    $response = Invoke-RestMethod -Uri $uri -Method Get
    $SpotData = $response.wind.$StationCode

    $StationName = $SpotData.windspot.stationnaam
    $windrichtingVan = $SpotData.windspot.windrichtingVan
    $windrichtingTot = $SpotData.windspot.windrichtingTot
    
    $LatestWindData = $SpotData.winddata[0]

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