<#
.SYNOPSIS
    Searches notes files for a given string.

.DESCRIPTION
    This script searches all .txt files in the notes directory for a specified string.
    It displays the filename and the lines where the string is found.

.PARAMETER SearchText
    The text to search for within the notes files.

.EXAMPLE
    Find-Note "keyword"

.NOTES
    Requires PowerShell 5.1 or later.  The notes directory defaults to the user's
    Documents\Notes folder.
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter the text to search for")]
    [string]$SearchText
)

#region Configuration
# The directory where the notes are stored. Defaults to Documents\Notes.
$NotesDirectory = if ($Env:NOTES_DIRECTORY) {
    $Env:NOTES_DIRECTORY
}
else {
    Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath "Notes"
}
# The editor to use for opening notes.
$NotesEditor = if ($Env:NOTES_EDITOR) {
    $NotesEditor
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
#endregion Configuration

#region Search Logic
try {
    # Get all text files in the notes directory
    $Files = Get-ChildItem -Path $NotesDirectory -Filter "*.txt" -File -ErrorAction Stop

    if ($Files) {
        $fileCount = 1  # Initialize file counter
        $fileList = @() # Initialize an array to store the files
        $searchWords = $SearchText -split '\s+' # Split the search text into individual words

        foreach ($File in $Files) {
            Write-Verbose "Searching file: $($File.FullName)"
            try {
                # Read the content of each file and search for the text
                $Content = Get-Content -Path $File.FullName -ErrorAction Stop
                $i = 0
                $found = $false #flag if the search text was found in the file
                foreach ($Line in $Content) {
                    $i++
                    # Check if all search words are present in the line
                    $allWordsPresent = $true
                    foreach ($word in $searchWords) { if ($Line -notmatch $word) { $allWordsPresent = $false; break } }
                    if ($allWordsPresent) {
                        # Display the filename and the line where the text is found
                        if ($found -eq $false) {
                            Write-Host "($fileCount) File: $($File.Name)" -ForegroundColor Green
                            $fileList += $File #add the file to the array
                            $found = $true
                        }
                        Write-Host "Line $($i): $Line" -ForegroundColor Cyan
                        Write-Host ""
                    }
                }
                if ($found -eq $true) {
                   $fileCount++ #increment the file count if the search text was found
                }
            }
            catch {
                Write-Warning "Error reading file $($File.Name): $($_.Exception.Message)"
            }
        }

        #region Menu Logic
        if ($fileList.Count -gt 0) {
            while ($true) {
                Write-Host "Options:"
                Write-Host "  (O) Open file by number"
                Write-Host "  (C) Clear search and try again"
                Write-Host "  (E) Exit"

                $choice = Read-Host "Enter your choice (O/C/E)"

                switch ($choice.ToUpper()) {
                    "O" {
                        $fileNumber = Read-Host "Enter the file number to open"
                        if ($fileNumber -match "^\d+$") {
                            $fileNumber = [int]$fileNumber
                            if ($fileNumber -gt 0 -and $fileNumber -lt $fileCount) {
                                $fileToOpen = $fileList[$fileNumber - 1].FullName
                                try {
                                    Invoke-Expression "& '$NotesEditor' '$fileToOpen'"
                                }
                                catch {
                                    Write-Error "Failed to open editor: $($_.Exception.Message)"
                                }
                            }
                            else {
                                Write-Host "Invalid file number." -ForegroundColor Red
                            }
                        }
                        else {
                            Write-Host "Invalid file number." -ForegroundColor Red
                        }
                    }
                    "C" {
                        # Clear the screen and prompt for new search text
                        Clear-Host
                        $SearchText = Read-Host "Enter the text to search for"
                        #restart the script
                        . $MyInvocation.MyCommand.Path -SearchText $SearchText
                        return # Exit the current execution to avoid falling through
                    }
                    "E" {
                        Write-Host "Exiting..."
                        return  # Exit the script
                    }
                    default {
                        Write-Host "Invalid choice. Please enter O, C, or E." -ForegroundColor Red
                    }
                }
            }
        }
        else {
            Write-Host "No files found with the specified search text." -ForegroundColor Yellow
        }
        #endregion Menu Logic
    }
    else {
        Write-Warning "No .txt files found in the notes directory: $NotesDirectory"
    }
}
catch {
    Write-Error "Error accessing notes directory: $($_.Exception.Message)"
}
#endregion Search Logic
