# Build and sync script for Databricks deployment

# 1. First create setup.py if it doesn't exist
if (-not (Test-Path "setup.py")) {
    @"
from setuptools import setup, find_packages

setup(
    name="core-ai-platform",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "beautifulsoup4",
        "pytz",
        "pyspark",
        "databricks-connect"
    ],
)
"@ | Out-File -FilePath "setup.py" -Encoding UTF8
}

# 2. Create dist directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "dist"

# 3. Clean up old builds
Remove-Item -Path "dist/*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "*.egg-info" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "build" -Force -Recurse -ErrorAction SilentlyContinue

# 4. Build wheel package
python -m pip install --upgrade build wheel
python setup.py bdist_wheel

# 5. Get the wheel file name
$wheelFile = Get-ChildItem -Path "dist" -Filter "*.whl" | Select-Object -First 1

# 6. Create a Python script to handle Databricks operations
@"
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.workspace import ImportFormat
import os
import base64

# Initialize Databricks workspace client
w = WorkspaceClient()

# Get the wheel file path
wheel_file = f"$($wheelFile.Name)"
local_path = os.path.join(os.getcwd(), "dist", wheel_file)

# Define Workspace path
workspace_path = f"/Shared/build/{wheel_file}"

# Upload new file to Workspace
try:
    # Read the wheel file as bytes
    with open(local_path, "rb") as f:
        wheel_content = f.read()
    
    # Convert to base64 for workspace import
    content = base64.b64encode(wheel_content).decode('utf-8')
    
    # Create /Shared/build directory if it doesn't exist
    try:
        w.workspace.mkdirs("/Shared/build")
        print("Created /Shared/build directory")
    except:
        pass

    # Delete existing file if it exists
    try:
        w.workspace.delete(workspace_path)
        print(f"Deleted existing file at {workspace_path}")
    except:
        pass

    # Upload the new file
    w.workspace.import_(
        path=workspace_path,
        format=ImportFormat.AUTO,
        content=content,
        overwrite=True
    )
    print(f"Successfully uploaded {wheel_file} to Workspace at {workspace_path}")
except Exception as e:
    print(f"Error uploading file: {e}")
    raise  # Re-raise the exception to see the full stack trace

"@ | Out-File -FilePath "distribute_to_workers.py" -Encoding UTF8

# 7. Run the distribution script
Write-Host "Building wheel package..."
if ($wheelFile) {
    Write-Host "Wheel package built successfully: $($wheelFile.Name)"
    Write-Host "Uploading to Databricks..."
    python distribute_to_workers.py
} else {
    Write-Host "Failed to build wheel package"
    exit 1
} 
