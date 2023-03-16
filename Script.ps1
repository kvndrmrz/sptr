. ./Get-SnMaster.ps1
[GC]::Collect()
. ./Get-SnSpotter.ps1 -Spotter BulkPlaylist
[GC]::Collect()
. ./Get-SnSpotter.ps1 -Spotter MyPlaylist
[GC]::Collect()
. ./Make-SpotterPlaylist.ps1
[GC]::Collect()
. ./Get-SnSpotter.ps1 -Spotter WeeklyCharts
[GC]::Collect()
