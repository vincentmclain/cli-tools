function Get-NotesTemplate {
    param (
        [string]$NotePath
    )
    if (!(Test-Path -Path $NotesPath -PathType Leaf)) {
        write-host "Creating $NotesPath"
        Add-Content -Path $NotesPath -Value "---"
        Add-Content -Path $NotesPath -Value "type: daily-note"
        Add-Content -Path $NotesPath -Value "note-date: $(Get-Date -Format "yyyy-MM-dd")"
        Add-Content -Path $NotesPath -Value "---"
    }
}
