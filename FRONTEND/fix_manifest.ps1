$path = "C:/Users/vivek/AppData/Local/Pub/Cache/hosted/pub.dev/tflite_v2-1.0.0/android/src/main/AndroidManifest.xml"
if (Test-Path $path) {
    $content = Get-Content $path
    $newContent = $content -replace 'package="[^"]*"', ''
    $newContent | Set-Content $path
    Write-Host "Successfully fixed manifest"
} else {
    Write-Host "Manifest path not found"
}
