#Requires -Version 5.1  # Or higher
. $PSScriptRoot\functions.ps1
. $PSScriptRoot\templates.ps1

<#
.SYNOPSIS
   Create a dated text file at a specific location and append text to it.

.DESCRIPTION
   This script creates a dated text file (YYYY-MM.txt) in the user's notes directory and appends text to it.
   If no arguments are provided, it opens the file in the default editor.

.PARAMETER Text
   The text to append to the notes file. If no text is provided, the script opens the notes file in the default editor.

.EXAMPLE
   notes.ps1 "Something you want to jot down"

.EXAMPLE
   Get-Clipboard | notes.ps1

.NOTES
   The notes directory defaults to the user's Documents\Notes folder.
#>

#region Configuration
$NotesDirectory = Get-NotesDirectory
$NotesEditor = Get-NotesEditor
$NotesFile = Get-Date -Format "yyyy-MM-dd"
$NotesFile = $NotesFile + ".txt"
$NotesPath = Join-Path -Path $NotesDirectory -ChildPath $NotesFile
#endregion Configuration

#region Main Logic
if ($args.Count -eq 0) {
    if ($PSBoundParameters.ContainsKey('Text')) {
        # Handle piped input when no explicit arguments are given
        $Text = $Text | Out-String
        # Add header
        Get-NotesTemplate -NotePath $NotesPath
        Add-Content -Path $NotesPath -Value "$Text`n"
    }
    else {
        # Check clipboard
        $ClipboardText = Get-Clipboard -ErrorAction SilentlyContinue
        if (-not [string]::IsNullOrEmpty($ClipboardText)) {
            $response = Read-Host "Text found in clipboard.  Paste into note? (y/n)"
            if ($response -match "^[Yy]") {
                Add-Content -Path $NotesPath -Value "$ClipboardText`n"
                Set-Clipboard -Value $null
            }
            else {
                # Open the file in the editor
                try {
                    write-host "Opening $NotesPath"
                    Invoke-Expression "& '$NotesEditor' '$NotesPath'"
                }
                catch {
                    Write-Error "Failed to open editor: $($_.Exception.Message)"
                    exit 1
                }
            }
        }
        else {
            # Open the file in the editor
            try {
                Invoke-Expression "& '$NotesEditor' '$NotesPath'"
            }
            catch {
                Write-Error "Failed to open editor: $($_.Exception.Message)"
                exit 1
            }
        }
    }
}
else {
    # Append the provided arguments to the file
    # Add header
    Get-NotesTemplate -NotePath $NotesPath
    $TextToAppend = $args -join " "
    Add-Content -Path $NotesPath -Value "$TextToAppend`n"
    Clear-Host
    Write-Host "Text appended to $NotesPath"
    Write-Host "Last 10 lines of the notes file"
    Write-Host "-------------------------------------------"
    Get-Content -Path $NotesPath -Tail 10 | ForEach-Object {
        Write-Host $_
    }
    Write-Host "-------------------------------------------"

    write-host "`n"
}
#endregion Main Logic
