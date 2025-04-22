#Requires -Version 5.1  # Or higher

<#
.SYNOPSIS
   Create a dated text file at a specific location and append text to it.

.DESCRIPTION
   This script creates a dated text file (YYYY-MM.txt) in the user's notes directory and appends text to it.
   If no arguments are provided, it opens the file in the default editor.

.PARAMETER Text
   The text to append to the notes file. If no text is provided, the script opens the notes file in the default editor.

.EXAMPLE
   howto.ps1 "Something you want to jot down"

.EXAMPLE
   Get-Clipboard | howto.ps1

.NOTES
   The notes directory defaults to the user's Documents\Notes folder.
#>

#region Configuration
$NotesDirectory = if ($Env:NOTES_DIRECTORY) {
    $Env:NOTES_DIRECTORY
}
else {
    Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath "Notes"
}
$NotesEditor = if ($Env:NOTES_EDITOR) {
    $Env:NOTES_EDITOR
}
else {
    # Attempt to find a suitable default editor
    if (Test-Path "C:\Program Files\Notepad++\notepad++.exe") {
        "C:\Program Files\Notepad++\notepad++.exe"
    }
    elseif (Get-Command code -ErrorAction SilentlyContinue) {
        "code" # VS Code
    }
    else {
        "notepad.exe" # Fallback to Notepad
    }
}

$NotesFile = Get-Date -Format "yyyy-MM-dd"
$NotesFile = $NotesFile + ".txt"
$NotesPath = Join-Path -Path $NotesDirectory -ChildPath $NotesFile
#endregion Configuration

#region Directory Creation
if (!(Test-Path -Path $NotesDirectory -PathType Container)) {
    while ($true) {
        $response = Read-Host "$NotesDirectory does not exist, do you want to create it? (y/n)"

        if ($response -match "^[Yy]") {
            try {
                New-Item -ItemType Directory -Path $NotesDirectory -Force | Out-Null
                break
            }
            catch {
                Write-Error "Failed to create directory: $($_.Exception.Message)"
                exit 1
            }
        }
        elseif ($response -match "^[Nn]") {
            exit
        }
        else {
            Write-Host "Please answer y or n"
        }
    }
}
#endregion Directory Creation

#region Main Logic
if ($args.Count -eq 0) {
    if ($PSBoundParameters.ContainsKey('Text')) {
        # Handle piped input when no explicit arguments are given
        $Text = $Text | Out-String

        # Check if the file exists.  If not, add the header.
        if (!(Test-Path -Path $NotesPath -PathType Leaf)) {
            write-host "Creating $NotesPath"
            Add-Content -Path $NotesPath -Value "---"
            Add-Content -Path $NotesPath -Value "type: daily-note"
            Add-Content -Path $NotesPath -Value "note-date: $(Get-Date -Format "yyyy-MM-dd")"
            Add-Content -Path $NotesPath -Value "---"
        }

        Add-Content -Path $NotesPath -Value "## $Text *howto*"
        Add-Content -Path $NotesPath -Value "---------------------------------------------"
        Add-Content -Path $NotesPath -Value "Context: [Why are you doing this?]"
        Add-Content -Path $NotesPath -Value "Steps:"
        Add-Content -Path $NotesPath -Value "1. "
        Add-Content -Path $NotesPath -Value "2. "
        Add-Content -Path $NotesPath -Value "Expected Outcome: [What should happen?]"
        Add-Content -Path $NotesPath -Value "Troubleshooting: [Common errors and how to fix them]"
        Add-Content -Path $NotesPath -Value "** Keywords and Tags (Plain text) **"

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
     # Check if the file exists.  If not, add the header.
    if (!(Test-Path -Path $NotesPath -PathType Leaf)) {
        write-host "Creating $NotesPath"
        Add-Content -Path $NotesPath -Value "---"
        Add-Content -Path $NotesPath -Value "type: daily-note"
        Add-Content -Path $NotesPath -Value "note-date: $(Get-Date -Format "yyyy-MM-dd")"
        Add-Content -Path $NotesPath -Value "---"
    }
    $TextToAppend = $args -join " "
    # Add-Content -Path $NotesPath -Value "$TextToAppend`n"
    Add-Content -Path $NotesPath -Value "## $TextToAppend *howto*"
    Add-Content -Path $NotesPath -Value "---------------------------------------------"
    Add-Content -Path $NotesPath -Value "Context: [Why are you doing this?]"
    Add-Content -Path $NotesPath -Value "Steps:"
    Add-Content -Path $NotesPath -Value "1. "
    Add-Content -Path $NotesPath -Value "2. "
    Add-Content -Path $NotesPath -Value "Expected Outcome: [What should happen?]"
    Add-Content -Path $NotesPath -Value "Troubleshooting: [Common errors and how to fix them]"
    Add-Content -Path $NotesPath -Value "** Keywords and Tags (Plain text) **"





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
