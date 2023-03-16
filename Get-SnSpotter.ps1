###Get-SnSpotter###
# Objectives
# 1. Get a snapshot of every playlist of interest to the spotter
# 2. Add IsUnique flag to each track if they are appearing in the spotter for the first time
# 3. Write snapshot to file and archive it
# 4. Write Sn_Spotter stats to file (e.g. Playlist;TotalItems;NewItems)
# 5. Get UniqueItems: filter unique tracks found in (2) and remove duplicates
# 6. Append UniqueItems to UniqueTracks_Spotter

param([Parameter(Mandatory)][string]$Spotter)
. "${Env:Work}/scr/mu/spotify/Spotter/Vars.ps1" -Spotter $Spotter

  # 1. Get a snapshot of every playlist of interest to the spotter
"[$(Get-TimeStamp)] Start Get-SnSpotter: ${Spotter}" | Tee-Object $Log -Append | Write-Debug
"[$(Get-TimeStamp)] Playlist count: $($Playlists.Length)" | Tee-Object $Log -Append | Write-Debug
"[$(Get-TimeStamp)] Initial UniqueTracks Count: $($UniqueTracks.Length)" | Tee-Object $Log -Append | Write-Debug
  # Get items from Sn_BulkPlaylist (IsUnique flag removed as it is different for each spotter)
if ($Spotter -eq 'BulkPlaylist') {
  $MSnapObj = Get-Content $MSnap | ConvertFrom-Json
  foreach ($Id in $Playlists.Id) {$MSnapObj | ? {$_.Playlist.Id -eq $Id} | % {$SnapObj.Add($_) > $Null}}
}
else {
  $BSnapObj = Get-Content $BSnap | jq '[.[] | {Playlist, Items: [.Items[] | del (.IsUnique)]}]' | ConvertFrom-Json
  foreach ($Id in $Playlists.Id) {$BSnapObj | ? {$_.Playlist.Id -eq $Id} | % {$SnapObj.Add($_) > $Null}}
}

  # 2a. [BulkPlaylist only] Add IsNew flag to tracks that are new to each playlist this week
"[$(Get-TimeStamp)] Sn_${Spotter} items: $($SnapObj.Items.Length)" | Tee-Object $Log -Append | Write-Verbose
if ($Spotter -eq 'BulkPLaylist') {
  "[$(Get-TimeStamp)] Adding IsNew property" | Tee-Object $Log -Append | Write-Verbose
  foreach ($Pl in $SnapObj) {
      $OldIds = $Null
      $OldIds = ($LastSnapObj | Where {$_.Playlist.Id -eq $Pl.Playlist.Id}).Items.Id
      if ($OldIds) {
	foreach ($Item in $Pl.Items) {
	  if ($Item.Id -notin $OldIds) {$Item | Add-Member -MemberType NoteProperty -Name IsNew -Value $True}
	  else {$Item | Add-Member -MemberType NoteProperty -Name IsNew -Value $False}
	}
      }
      else {
	"[$(Get-TimeStamp)] $($Pl.Playlist.Name)[$($Pl.Playlist.Id)] not in $($LastSnap.Name)" | Tee-Object $Log -Append | Write-Verbose
	$Pl.Items | Add-Member -MemberType NoteProperty -Name IsNew -Value $True
      }
  }
}

  # 2b. Add IsUnique flag to each track if they are appearing in the spotter for the first time
"[$(Get-TimeStamp)] Adding IsUnique property" | Tee-Object $Log -Append | Write-Verbose
  # Tag unique items as True; identical items may be labeled as New; tag remaining items as False
Measure-Command -Expression {
  $SnapObj.Items | ? {$_.Id -notin $UniqueTracks.Id} | Add-Member -Name IsUnique -Value $True -MemberType NoteProperty -Force
  $SnapObj.Items | Where -Property IsUnique -ne $True | Add-Member -Name IsUnique -Value $False -MemberType NoteProperty -Force
} | Write-Verbose

  # 3. Write snapshot to file and archive it
"[$(Get-TimeStamp)] Creating Sn_${Spotter}" | Tee-Object $Log -Append | Write-Verbose
$SnapObj | ConvertTo-Json -Depth 100 | Out-File $Snap
7z a $SnapArch $Snap
7z l $SnapArch
"[$(Get-TimeStamp)] Sn_${Spotter} exists: $(Test-Path $Snap)" | Tee-Object $Log -Append | Write-Debug

  # 4. Write Sn_Spotter stats to file (e.g. Playlist;TotalItems;NewItems)
"`r`n---${Date}---" | Out-File $Stat -Append
$SnPlaylists = $SnapObj.Playlist | Sort-Object -Property Id -Unique
$Playlists | ? {$_.Id -notin $SnPlaylists.Id} | % {"$($_.Id);$($_.Name);x;x" | Out-File $Stat -Append}
foreach ($Pl in $SnPlaylists) {
  $PlCount = ($SnapObj | ? {$_.Playlist.Id -eq $Pl.Id} | Select-Object -ExpandProperty Items).Length
  $PlNewCount = ($SnapObj | ? {$_.Playlist.Id -eq $Pl.Id} | Select-Object -ExpandProperty Items | Where IsNew -eq $True ).Length
  $NewSum += $PlNewCount
  "$($Pl.Id);$($Pl.Name);${PlCount};${PlNewCount}" | Out-File $Stat -Append
}
"Total;$($SnapObj.Items.Length);${NewSum}" | Out-File $Stat -Append

  # 5. Get UniqueItems: filter unique tracks found in (2) and remove duplicates
  # UniqueItems w/ duplicates will only be attributed to the first playlist specified in the order that they appear in Playlists_${Spotter}
  # UniqueItems will be grouped and ordered by playlist such that the playlist w/ fewest UniqueItems appears first
Measure-Command -Expression {
  "[$(Get-TimeStamp)] Filtering UniqueItems" | Tee-Object $Log -Append | Write-Verbose
  $UniqueItems = $SnapObj | Select-Object -Property @{n='Playlist';e={$_.Playlist.Name}},@{n='PlaylistId';e={$_.Playlist.Id}} -ExpandProperty Items | Where IsUnique -eq $True | `
    Group-Object -Property Id | % {$_ | Select -ExpandProperty Group | Select -First 1} | `
    Group-Object -Property Playlist | Sort-Object -Property Count | Select-Object -ExpandProperty Group
} | Write-Verbose
"[$(Get-TimeStamp)] UniqueItems Count: $($UniqueItems.Length)" | Tee-Object $Log -Append | Write-Debug
"UniqueItems:$($UniqueItems.Length)" | Out-File $Stat -Append

  # 6. Append UniqueItems to UniqueTracksTracks_Spotter.tsv
Measure-Command -Expression {
  $UniqueItems | Select-Object -Property `
    @{n='SnapshotDate';e={$Date}}, `
    @{n='DateAdded';e={$_.AddedAt | Get-Date -UFormat "%Y-%m-%d"}}, `
    Id, `
    @{n='Artist';e={$_.Artists[0].Name}}, `
    Name, `
    Playlist, `
    PlaylistId | Export-Tsv -Path $F_UniqueTracks -Append
} | Write-Verbose
  # check that UniqueItems were added by checking the new size of UniqueTracksTracks_Spotter.tsv
"[$(Get-TimeStamp)] Final UniqueTracks Count: $((Import-Tsv $F_UniqueTracks).Length)" | Tee-Object $Log -Append | Write-Debug

  # 7. Convert snapshot to tab-delimited format for importing to MySQL
"[$(Get-TimeStamp)] Convert Sn_${Spotter} to Tsv" | Tee-Object $Log -Append | Write-Debug
$SnapObj | % {
  $PlId = $_.Playlist.Id
  $_.Items | Select `
    @{n='PlaylistId';e={$PlId}}, `
    PlaylistIndex, `
    IsNew, `
    IsUnique, `
    Id, `
    AddedAt, `
    @{n='AlbumId';e={$_.Album.Id}}, `
    @{n='Artists';e={$_.Artists | Select Id | ConvertTo-Json -Compress}} | `
    Export-Tsv -Path $SnapTsv -Append
}
7z a $SnapTsvArch $SnapTsv
7z l $SnapTsvArch
"[$(Get-TimeStamp)] End Get-SnSpotter: ${Spotter}" | Tee-Object $Log -Append | Write-Debug
#>
