# PowerShell script to run ctest multiple times and stop on first failure

# Initialize a counter for successful runs
$successCount = 0

# Specify the number of times to run the tests
$maxAttempts = 100

# Set verbose preference to suppress verbose messages
$VerbosePreference = 'SilentlyContinue'

# Loop to run ctest multiple times
for ($i = 1; $i -le $maxAttempts; $i++)
{
    Write-Host "Attempt $i of $maxAttempts"
    # Run ctest with verbose output
    ctest --test-dir "build" -C Debug -VV > $null 2>&1

    # Check the exit status of the last command (ctest in this case)
    if ($LASTEXITCODE -eq 0) {
        # Increment the success counter if ctest succeeded
        $successCount++
    } else {
        # Exit the loop if ctest failed
        Write-Host "Test failed on attempt $i"
        break
    }
}

# Print the number of successful runs
Write-Host "Number of successful runs: $successCount"
