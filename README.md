# ActueleWind
Scripting to get specific wind data.

The scripts now read directly from Rijkswaterstaat Waterinfo instead of polling
`actuelewind.nl`.

Default station `6225` is mapped to Waterinfo location
`ijmuiden.buitenhaven`. You can also pass a Waterinfo `locationCode` directly,
for example `vlissingen` or `texel.hors`.

Waterinfo reports a 600 second refresh interval for the wind speed endpoint, so
polling more often than every 10 minutes is not useful.
