param([Parameter(Mandatory)][string]$Spotter)

  # Important variables
$Date	      = Get-Date -UFormat "%F"
$Year	      = Get-Date -UFormat %Y
$Playlists    = $Null
$PlItems      = [System.Collections.ArrayList]@()
$SnapObj      = [System.Collections.ArrayList]@()   # Collection of items returned from ALL playlists 
$MSnapObj     = [System.Collections.ArrayList]@()   # Collection of items returned from ALL playlists 
$BSnapObj     = [System.Collections.ArrayList]@()   # Collection of items returned from ALL playlists 
$UniqueTracks    = [System.Collections.ArrayList]@()   # Unique tracks discovered so far
$UniqueItems = $Null				    # Unique tracks discovered this week
$NewSum = 0

  # Important directories
$Sptr	  = "${Env:Work}/mu/gmu/song/Spotter"
$Arch	  = "${Sptr}/Archive"
$Logs	  = "${Env:Work}/log/pwsh"
$Sptrs	  = "${Env:Work}/scr/mu/spotify"

  # Variables dependent on Spotter called
switch ($Spotter) {
  'Master' {
    $Props	= 'next,items(added_at,track(id,name,artists(id,name),album(id,name,release_date)))'
    $F_UniqueAlbums  = Join-Path -Path $Sptr -ChildPath "Master/Ualbs_Master.tsv"
    $F_UniqueArtists = Join-Path -Path $Sptr -ChildPath "Master/Uarts_Master.tsv"
    $UniqueArtists = Import-Tsv $F_UniqueArtists
    $UniqueAlbums	= Import-Tsv $F_UniqueAlbums
  }
  'BulkPlaylist' {
    # $LastDate     = (Get-Date).AddDays(-7) | Get-Date -UFormat  "%F"
    $LastDate     = '2023-02-28'
    $LastSnap     = Get-ChildItem "${Sptr}/BulkPlaylist/Sn_BulkPlaylist/${LastDate}_Sn_BulkPlaylist.json" 
    $LastSnapObj  = [System.Collections.ArrayList]@()   # Collection of items returned from ALL playlists 
    Get-Content -Path $LastSnap.FullName | ConvertFrom-Json | % {$LastSnapObj.Add($_) > $Null}
  }
}

  # Important files
$F_UniqueTracks  = Join-Path -Path $Sptr -ChildPath "${Spotter}/Utks_${Spotter}.tsv"
$UniqueTracks    = Import-Tsv -Path $F_UniqueTracks
$F_Playlists  = Join-Path -Path $Sptr -ChildPath "${Spotter}/Pls_${Spotter}.tsv"
$Playlists    = Import-Tsv -Path $F_Playlists | Where Tracking -eq $True
$MSnap	      = Join-Path -Path $Sptr -ChildPath "Master/Sn_Master/${Date}_Sn_Master.json"
$BSnap	      = Join-Path -Path $Sptr -ChildPath "BulkPlaylist/Sn_BulkPlaylist/${Date}_Sn_BulkPlaylist.json"
$Snap	      = Join-Path -Path $Sptr -ChildPath "${Spotter}/Sn_${Spotter}/${Date}_Sn_${Spotter}.json"
$SnapTsv      = Join-Path -Path $Sptr -ChildPath "${Spotter}/Sn_${Spotter}_Tsv/${Date}_Sn_${Spotter}.tsv"
$PlName	      = "${Date}_${Spotter}"
$PlTsv	      = Join-Path -Path $Sptr -ChildPath "${Spotter}/Pl_${Spotter}/${PlName}.tsv"
$SnapArch     = Join-Path -Path $Arch -ChildPath "${Spotter}/${Year}_Sn_${Spotter}.7z"
$PlArch       = Join-Path -Path $Arch -ChildPath "${Spotter}/Pl_${Spotter}/$($PlName -replace '-\d\d-\d\d').7z"
$SnapTsvArch  = Join-Path -Path $Arch -ChildPath "${Spotter}/${Year}_Sn_${Spotter}_Tsv.7z"
$Stat	      = Join-Path -Path $Arch -ChildPath "${Spotter}/${Year}_St_${Spotter}.txt"
$Log	      = Join-Path -Path $Logs -ChildPath ((Split-Path $MyInvocation.PSCommandPath -Leaf) -replace 'ps1','log')
