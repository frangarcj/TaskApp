# Utilidades de prueba de interfaz en Windows: capturas y clics de ratón.
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mouse {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, IntPtr e);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    public static void Click(int x, int y) {
        SetCursorPos(x, y);
        mouse_event(0x0002, 0, 0, 0, IntPtr.Zero);
        mouse_event(0x0004, 0, 0, 0, IntPtr.Zero);
    }
}
"@
[Mouse]::SetProcessDPIAware() | Out-Null

function Save-Screenshot([string]$name) {
    New-Item -ItemType Directory -Force -Path shots | Out-Null
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $bitmap.Save("shots/$name.png", [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "captura: shots/$name.png ($($bounds.Width)x$($bounds.Height))"
}

function Click-At([int]$x, [int]$y) { [Mouse]::Click($x, $y); Start-Sleep -Milliseconds 1500 }
