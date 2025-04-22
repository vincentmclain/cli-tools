<#
.SYNOPSIS
    Returns the notes directory.

.DESCRIPTION
    Gets the value of the NOTES_DIRECTORY environment variable or
    uses a default value if it is not set.

.PARAMETER Year
    The year to use in the default notes directory if the NOTES_DIRECTORY
    environment variable is not set. Defaults to the current year.

.EXAMPLE
    $NotesDirectory = Get-NotesDirectory

.NOTES
    The default notes directory is "$env:USERPROFILE\Workspace\@Archive\<Year>\@Drafts" if
    the NOTES_DIRECTORY environment variable is not set.
#>
function Get-NotesDirectory {
    param (
        [string]$Year = (Get-Date).Year.ToString()
    )

    if ($Env:NOTES_DIRECTORY) {
        $NotesDirectory = $Env:NOTES_DIRECTORY
    }
    else {
        $NotesDirectory = Join-Path -Path "$env:USERPROFILE\Workspace\@Archive\$Year" -ChildPath "@Drafts"
    }
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
    return $NotesDirectory
}


function Get-NotesEditor {
    if ($Env:NOTES_EDITOR) {
        $Env:NOTES_EDITOR
    }
    else {
        # Attempt to find a suitable default editor
        if (Test-Path "C:\Program Files\Notepad++\notepad++.exe") {
            return "C:\Program Files\Notepad++\notepad++.exe"
        }
        elseif (Get-Command code -ErrorAction SilentlyContinue) {
            return "code" # VS Code
        }
        else {
            return "notepad.exe" # Fallback to Notepad
        }
    }
}
