# Keep Screen Awake - Move Mouse Periodically
# Evita que a tela desligue durante processos longos

param(
    [int]$IntervalSeconds = 5,  # Intervalo entre movimentos (segundos)
    [switch]$Verbose
)

Write-Host "🖱️  Keep Screen Awake" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Movendo mouse a cada $IntervalSeconds segundos"
Write-Host "Pressione Ctrl+C para parar"
Write-Host ""

# Adiciona assemblies necessários para mover o mouse
Add-Type -AssemblyName System.Windows.Forms

# Adiciona funções para simular clique do mouse
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MouseSimulator {
    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int cButtons, int dwExtraInfo);
    
    public const int MOUSEEVENTF_LEFTDOWN = 0x02;
    public const int MOUSEEVENTF_LEFTUP = 0x04;
    
    public static void Click() {
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
    }
}
"@

$startTime = Get-Date
$iterations = 0

try {
    while ($true) {
        $iterations++
        
        # Simula clique do mouse
        [MouseSimulator]::Click()
        
        if ($Verbose) {
            $elapsed = (Get-Date) - $startTime
            Write-Host "[$($elapsed.ToString('hh\:mm\:ss'))] Clique #$iterations - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
        }
        
        # Aguarda próximo intervalo
        Start-Sleep -Seconds $IntervalSeconds
    }
}
catch {
    Write-Host "`n⚠️  Script interrompido" -ForegroundColor Yellow
}
finally {
    $elapsed = (Get-Date) - $startTime
    Write-Host "`n✅ Manteve tela ativa por: $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Green
    Write-Host "Total de movimentos: $iterations" -ForegroundColor Cyan
}
