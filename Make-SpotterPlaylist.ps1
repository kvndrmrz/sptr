  # Make playlist and add items to playlist
"[$(Get-TimeStamp)] Making ${PlName} Spotify playlist" | Tee-Object $Log -Append | Write-Verbose
try {
  $NewPlaylist = New-Playlist -Name $PlName -UserId $SpotifyProfile.id -ApplicationName $App.Name
  "[$(Get-TimeStamp)] Playlist created. Name: $($NewPlaylist.name); Id: $($NewPlaylist.id)" | Tee-Object $Log -Append | Write-Verbose
}
catch {"[$(Get-TimeStamp)] [ERROR] $($Error[0].Exception.Message)" | Tee-Object $Log -Append | Write-Error}

  # Add $UniqueItems to newly created playlist
Add-PlaylistItem -Id $NewPlaylist.id -ItemId ($UniqueItems.Id -replace '^','spotify:track:') -ApplicationName $App.Name 2>> $Null
Save-PlaylistAndItems -Id $NewPlaylist.id -Path $PlTsv -Tsv -Silent
7z a $PlArch $PlTsv
7z l $PlArch

