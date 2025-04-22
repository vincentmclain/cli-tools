. $PSScriptRoot\functions.ps1

#region Configuration
# Use the same logic as note.ps1 to determine the Notes Directory
$NotesDirectory = Get-NotesDirectory

$TodoFilePath = Join-Path -Path $NotesDirectory -ChildPath "todo.txt"
$DoneFilePath = Join-Path -Path $NotesDirectory -ChildPath "done.txt"
#endregion Configuration

# Function to read the todo.txt file
function Read-TodoFile {
    [CmdletBinding()]
    param()

    try {
        # Check if the todo.txt file exists
        if (Test-Path -Path $TodoFilePath) {
            # Read the content of the todo.txt file
            $TodoItems = Get-Content -Path $TodoFilePath
            return $TodoItems
        } else {
            Write-Warning "todo.txt file not found.  Creating an empty one."
            New-Item -ItemType File -Path $TodoFilePath | Out-Null
            return @()
        }
    }
    catch {
        Write-Error "Error reading todo.txt file: $($_.Exception.Message)"
        return $null
    }
}

# Function to complete a todo item
function Complete-TodoItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [int]$Index
    )

    # Read the todo items
    $TodoItems = Read-TodoFile

    # Validate the index
    if ($Index -lt 0 -or $Index -ge $TodoItems.Count) {
        Write-Error "Invalid index. Index must be between 0 and $($TodoItems.Count - 1)."
        return
    }

    try {
        # Get the completed item
        $CompletedItem = $TodoItems[$Index]

        # Add the completion date to the completed item
        $CompletedItem = "x " + (Get-Date -Format "yyyy-MM-dd") + " " + $CompletedItem

        # Append the completed item to done.txt
        Add-Content -Path $DoneFilePath -Value $CompletedItem

        # Remove the completed item from the todo items array
        $TodoItems = $TodoItems | Where-Object {$PSItem -ne $TodoItems[$Index]}

        # Write the updated todo items back to todo.txt
        $TodoItems | Set-Content -Path $TodoFilePath

        Write-Host "Completed item '$CompletedItem' and moved to done.txt"
    }
    catch {
        Write-Error "Error completing todo item: $($_.Exception.Message)"
    }
}

# Function to add a todo item
function Add-TodoItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Text
    )

    try {
        # Append the new item to todo.txt
        Add-Content -Path $TodoFilePath -Value $Text

        Write-Host "Added item '$Text' to todo.txt"
    }
    catch {
        Write-Error "Error adding todo item: $($_.Exception.Message)"
    }
}

# Example usage:
$Todos = Read-TodoFile
// clear the screen
Clear-Host
Write-Host "Hints:"
Write-Host "    Priority: (a,b,c)"
Write-Host "    Context: @email"
Write-Host "    Project +project"
Write-Host "  "
Write-Host "Example: (a) Schedule Goodwill pickup +GarageSale @phone"
Write-Host "  "
Write-Host "Todo items:"
Write-Host "---------------------------------------------------------"
for ($i = 0; $i -lt $Todos.Count; $i++) {
    Write-Host "$i : $($Todos[$i])"
}
Write-Host "  "
# Prompt the user for the index of the item to complete (or 'a' to add a new item)
# AI add simple header explaining the todo.txt file format
$IndexToComplete = Read-Host "Enter the index of the item to complete (or 'a' to add a new item, 'q' to quit):"

if ($IndexToComplete -eq "a") {
    # Prompt the user for the text of the new todo item
    $NewTodoText = Read-Host "Enter the text of the new todo item"

    # Call the Add-TodoItem function with the text provided by the user
    $NewTodoText | Add-TodoItem
} else {
    if ($IndexToComplete -eq "q") {
        Write-Host "Exiting..."
        exit
    }
    # Call the Complete-TodoItem function with the index provided by the user
    $IndexToComplete | Complete-TodoItem
}
