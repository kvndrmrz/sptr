###Get-SnMaster###
# Objectives
# 1. Get a snapshot of every playlist of interest
# 2. Write any unique entities we've encountered to respective 'Unique{Entity}' file
# 3. Modify snapshot to adhere to our naming conventions
# 4. Archive shapshot of playlists

. "${Env:Work}/scr/mu/spotify/Spotter/Vars.ps1" -Spotter 'Master'

 # 1. Get playlists of interest
"[$(Get-TimeStamp)] Start Get-SnMaster" | Tee-Object $Log -Append | Write-Debug
"[$(Get-TimeStamp)] Playlist count: $($Playlists.Length)" | Tee-Object $Log -Append | Write-Debug
foreach ($Playlist in $Playlists) {
 "[$(Get-TimeStamp)] Requesting $($Playlist.Name) items" | Tee-Object $Log -Append | Write-Debug
 try {
   $PlItems = Get-PlaylistItems -Id $Playlist.Id -ApplicationName $App.Name -Field $Props
   for ($i = 0;$i -lt $PlItems.Length;$i++) {
      $PlItems[$i] | Add-Member -MemberType NoteProperty -Name PlaylistIndex -Value $($i+1)
   }
   # Add playlist+items to Master snapshot obj
   $MSnapObj.Add([pscustomobject]@{
     Playlist=($Playlist | Select -Property Id,Name)
     Items=$PlItems
   }) > $Null
   "[$(Get-TimeStamp)] $($Playlist.Name) Count: $($PlItems.Length); AllItems Count: $($MSnapObj.Items.Length)" | `
     Tee-Object $Log -Append | Write-Debug
 }
 catch {"[$(Get-TimeStamp)] [ERROR] $($Playlist.Name) not found" | Tee-Object $Log -Append | Write-Debug}
 Start-Sleep -Milliseconds 750
}

# 2a. Before removing the 'release_date' property from our playlist items, get and write all new albums to F_UniqueAlbums file
"[$(Get-TimeStamp)] Filtering UniqueAlbums" | Tee-Object $Log -Append | Write-Verbose
$MSnapObj.Items.track.album | Where-Object {$_.id -notin $UniqueAlbums.Id} | Sort-Object -Property id -Unique | Select-Object -Property `
 @{n='ReleaseDate';e={$_.release_date}}, `
 @{n='Id';e={$_.id}}, `
 @{n='Name';e={$_.name}} | `
 Export-Tsv -Path $F_UniqueAlbums -Append

 # 3. Modify $MSnapObj to adhere to our naming conventions and write to file
"[$(Get-TimeStamp)] Creating Sn_Master" | Tee-Object $Log -Append | Write-Verbose
$MSnapObj = $MSnapObj | ConvertTo-Json -Depth 100 | `
 jq '[.[] | {Playlist, Items: [.Items[] | {PlaylistIndex, AddedAt: .added_at, Id: (try .track.id), Name: (try .track.name), Album: (try (.track | .album | {Id: .id,Name: .name})), Artists: (try (.track | [.artists[] | {Id: .id, Name: .name}]))}]}]' | `
 Tee-Object $MSnap | ConvertFrom-Json

  # 2b. Get all Tracks/artists to add to our list of unique entities
"[$(Get-TimeStamp)] Filtering UniqueTracks" | Tee-Object $Log -Append | Write-Verbose
$MSnapObj.Items | Where-Object {$_.Id -notin $UniqueTracks.Id} | Sort-Object -Property Id -Unique | Select `
  Id, `
  Name, `
  @{n='Album';e={$_.Album | ConvertTo-Json -Compress}}, `
  @{n='Artists';e={$_.Artists | ConvertTo-Json -Compress}} | `
  Export-Tsv -Path $F_UniqueTracks -Append
"[$(Get-TimeStamp)] Filtering UniqueArtists" | Tee-Object $Log -Append | Write-Verbose
$MSnapObj.Items.Artists | Where-Object {$_.Id -notin $UniqueArtists.Id} | Sort-Object -Property Id -Unique | `
  Export-Tsv -Path $F_UniqueArtists -Append

  # 4. Archive shapshot of playlists
7z a $SnapArch $MSnap
7z l $SnapArch
"[$(Get-TimeStamp)] Sn_Master exists: $(Test-Path $MSnap)" | Tee-Object $Log -Append | Write-Debug

  # 7. Convert snapshot to tab-delimited format for importing to MySQL
"[$(Get-TimeStamp)] Convert Sn_Master to Tsv" | Tee-Object $Log -Append | Write-Debug
$MSnapObj | % {
  $PlId = $_.Playlist.Id
  $_.Items | Select `
    @{n='PlaylistId';e={$PlId}}, `
    PlaylistIndex, `
    Id, `
    AddedAt, `
    @{n='AlbumId';e={$_.Album.Id}}, `
    @{n='Artists';e={$_.Artists | Select Id | ConvertTo-Json -Compress}} | `
    Export-Tsv -Path $SnapTsv -Append
}
7z a $SnapTsvArch $SnapTsv
7z l $SnapTsvArch
"[$(Get-TimeStamp)] End Get-SnMaster" | Tee-Object $Log -Append | Write-Debug
#>

#>
