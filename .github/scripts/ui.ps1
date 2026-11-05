# Utilidades de prueba de interfaz en Windows: ventana de la app, controles,
# clics y capturas.
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public struct RECT { public int Left, Top, Right, Bottom; }
public static class Win {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc f, IntPtr p);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, IntPtr e);
    public static List<IntPtr> Children(IntPtr parent) {
        var list = new List<IntPtr>();
        EnumChildWindows(parent, (h, p) => { list.Add(h); return true; }, IntPtr.Zero);
        return list;
    }
    public static string Cls(IntPtr h) { var s = new StringBuilder(256); GetClassName(h, s, 256); return s.ToString(); }
    public static string Text(IntPtr h) { var s = new StringBuilder(512); GetWindowText(h, s, 512); return s.ToString(); }
    public static void Click(int x, int y, bool right) {
        SetCursorPos(x, y);
        mouse_event(right ? 0x0008u : 0x0002u, 0, 0, 0, IntPtr.Zero);
        mouse_event(right ? 0x0010u : 0x0004u, 0, 0, 0, IntPtr.Zero);
    }
}
"@
[Win]::SetProcessDPIAware() | Out-Null

# Ventana principal de SwiftOpenUI, delante de todo y en una posición fija.
function Get-AppWindow {
    $h = [Win]::FindWindow("SwiftOpenUIMainWindow", $null)
    if ($h -eq [IntPtr]::Zero) { throw "No se encuentra la ventana SwiftOpenUIMainWindow" }
    [Win]::ShowWindow($h, 9) | Out-Null
    [Win]::SetWindowPos($h, [IntPtr](-1), 0, 0, 900, 700, 0x0040) | Out-Null   # HWND_TOPMOST, SWP_SHOWWINDOW
    [Win]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 800
    return $h
}

# Controles visibles de la ventana: clase, texto y rectángulo en pantalla.
function Get-Controls([IntPtr]$h) {
    foreach ($c in [Win]::Children($h)) {
        if (-not [Win]::IsWindowVisible($c)) { continue }
        $r = New-Object RECT; [Win]::GetWindowRect($c, [ref]$r) | Out-Null
        [pscustomobject]@{ Class = [Win]::Cls($c); Text = [Win]::Text($c);
            X = $r.Left; Y = $r.Top; W = $r.Right - $r.Left; H = $r.Bottom - $r.Top }
    }
}

function Save-Controls([IntPtr]$h, [string]$name) {
    New-Item -ItemType Directory -Force -Path shots | Out-Null
    Get-Controls $h | Format-Table -AutoSize | Out-String -Width 300 | Out-File "shots/$name.txt"
}

function Save-Screenshot([string]$name) {
    New-Item -ItemType Directory -Force -Path shots | Out-Null
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $bitmap.Save("shots/$name.png", [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "captura: shots/$name.png"
}

function Click-At([int]$x, [int]$y, [switch]$Right) { [Win]::Click($x, $y, $Right.IsPresent); Start-Sleep -Milliseconds 1500 }

# Clic en el centro del primer control visible cuyo texto sea $text.
function Click-Text([IntPtr]$h, [string]$text, [switch]$Right) {
    $c = Get-Controls $h | Where-Object { $_.Text -eq $text } | Select-Object -First 1
    if (-not $c) { Write-Host "no hay control con texto '$text'"; return $false }
    Click-At ($c.X + [int]($c.W / 2)) ($c.Y + [int]($c.H / 2)) -Right:$Right
    return $true
}
