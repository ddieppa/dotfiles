# -----------------------------------------------------------
# ISABELLA EDUCATION FOLDER INITIALIZATION (GRADE 4)
# -----------------------------------------------------------
$basePath = "E:\QSync\2-Areas\Family\Isabella\Education\2025-2026_Grade_4"

# Define the subfolders and their purpose for the READMEs
$structure = [ordered]@{
    "."                   = "# 🎓 Grade 4 (2025-2026)`n`nThis folder contains all academic records for Isabella's 4th grade year at Miami-Dade County Public Schools."
    "Report_Cards"        = "# 📝 Report Cards`n`nQuarterly (Q1-Q4) and Final report cards. Requested by admission committees to track academic consistency."
    "Standardized_Tests"  = "# 📊 Standardized Tests`n`nIncludes FAST (PM1, PM2, PM3), STAR Reading/Math, and i-Ready diagnostic results."
    "Admin_&_IEP"         = "# 📂 Administration & Support`n`nRegistration forms, School communication, and Psychoeducational Evaluations or IEP/504 documents."
}

Write-Host "🚀 Initializing Education Folder Structure on E:\QSync..." -ForegroundColor Cyan

foreach ($folder in $structure.Keys) {
    # Determine the target path for the folder
    $targetPath = if ($folder -eq ".") { $basePath } else { Join-Path -Path $basePath -ChildPath $folder }
    $readmePath = Join-Path -Path $targetPath -ChildPath "README.md"

    # 1. Create the Directory
    if (-not (Test-Path $targetPath)) {
        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
        Write-Host "   ✅ Created: $folder" -ForegroundColor Gray
    } else {
        Write-Host "   ℹ️  Exists: $folder" -ForegroundColor DarkGray
    }

    # 2. Create the README
    try {
        Set-Content -Path $readmePath -Value $structure[$folder] -Force
        Write-Host "      📄 README generated." -ForegroundColor DarkGray
    } catch {
        Write-Host "      ⚠️  Could not create README in $folder" -ForegroundColor Yellow
    }
}

Write-Host "`n✨ Structure is ready. You can now move your PDFs into these folders." -ForegroundColor Green