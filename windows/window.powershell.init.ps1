# How to use this init file:
# 1. Add path of this file to enviroment variable
# 2. Each time you open a new terminal, you can use `. i` to load this file (file name is: i.ps1)

function Prompt {
    $folder = Split-Path -Leaf -Path (Get-Location)  # Get current folder name
    $gitBranch = & git rev-parse --abbrev-ref HEAD 2>$null  # Get current Git branch
    
    if ($gitBranch) {
        # If in a Git repository, show folder and branch (branch in blue)
        Write-Host "$folder " -NoNewline
        Write-Host "$gitBranch" -ForegroundColor Blue -NoNewline
    } else {
        # If not in a Git repository, show only folder
        Write-Host "$folder" -NoNewline
    }
    return " > "
}

function cds {
    param (
        [int]$index = 0  # Default index is 0
    )

    # Define an array of folder paths
    $folders = @(
        "C:\Users\laidq\wsl-data",
        "C:\Users\laidq\wsl-data\car-evaluation",
        "\data\custom-script"
    )

    # Check if the index is valid
    if ($index -ge 0 -and $index -lt $folders.Length) {
        # Change directory to the specified folder
        try {
            Set-Location -Path $folders[$index] -ErrorAction Stop
        } catch {
            Write-Host "Failed to change directory."
        }
    } else {
        Write-Host "Invalid index. Please provide an index between 0 and $($folders.Length - 1)."
    }
}

function gita {
    param (
        [string]$Message  # Optional commit message as an argument
    )

    # Define color codes (using Write-Host for color in PowerShell)
    $YELLOW = "Yellow"
    $RESET = "White"

    # Check if the first argument is provided
    if (-not $Message) {
        # Check if the DEFAULT_MSG environment variable is set
        if ($env:DEFAULT_MSG) {
            # Print the current DEFAULT_MSG in yellow
            Write-Host "Commit message: " -NoNewline
            Write-Host "'$env:DEFAULT_MSG'" -ForegroundColor $YELLOW
            # Prompt the user to enter a new message or press Enter to use the default
            $NEW_MSG = Read-Host "Press Enter to use this message or enter a new one"
            # Use the new message if provided, otherwise use DEFAULT_MSG
            $Message = if ($NEW_MSG) { $NEW_MSG } else { $env:DEFAULT_MSG }
        } else {
            # Prompt the user for input if DEFAULT_MSG is not set
            $env:DEFAULT_MSG = Read-Host "Enter commit message"
            $Message = $env:DEFAULT_MSG
        }
    }

    $Message = $Message -replace '"', ''

    # Execute git commands
    & git add -A
    & git commit -m "$Message"
}

function lfmt {
    $ruffPath = "C:\Users\laidq\wsl-data\core-ai-platform\.venv\Scripts\ruff.exe"
    & $ruffPath format
    & $ruffPath check --select I --fix .
}

function pyac {
    param (
        [int]$key1 = 0
    )

    # Define the base paths relative to the keys
    $basePaths = @(
        (Get-Location).Path,   # Key 0: Current folder
        "C:\Users\laidq\wsl-data\core-ai-platform",               # Key 1
        "D:\tmp",               # Key 2
        "E:\tmp"                # Key 3 (you can modify this path as needed)
    )

    # Validate the key
    if ($key1 -ge 0 -and $key1 -lt $basePaths.Count) {
        $venvPath = Join-Path -Path $basePaths[$key1] -ChildPath ".venv"

        if (Test-Path $venvPath) {
            $activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate.ps1"
            
            if (Test-Path $activateScript) {
                . $activateScript
                Write-Host "Virtual environment activated: $venvPath"
            } else {
                Write-Host "Activation script not found at: $activateScript" -ForegroundColor Red
            }
        } else {
            Write-Host "Virtual environment folder not found: $venvPath" -ForegroundColor Red
        }
    } else {
        Write-Host "Invalid key. Please use 0, 1, 2, or 3." -ForegroundColor Red
    }
}

