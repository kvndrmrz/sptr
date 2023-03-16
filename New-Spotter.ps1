function New-Spotter {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Name)

  BEGIN {
    $Sptr = 'e:/work/mu/gmu/song/Spotter'
    $Year = Get-Date -UFormat %Y
    mkdir "${Sptr}/${Name}"
    mkdir "${Sptr}/${Name}/Pl_${Name}"
    mkdir "${Sptr}/${Name}/Sn_${Name}"
    touch "${Sptr}/${Name}/UniqueTracks_${Name}.tsv"
    mkdir "${Sptr}/Archive/${Name}"
    mkdir "${Sptr}/Archive/${Name}/Pl_${Name}"
    touch "${Sptr}/Archive/${Name}/${Year}_St_${Name}.txt"
    Import-Tsv "${Sptr}/Master/Playlists_Master.tsv" | Select DateAdded,Id,Tracking,Name | Export-Tsv -Path  "${Sptr}/${Name}/Playlists_${Name}.tsv"
  }
}

