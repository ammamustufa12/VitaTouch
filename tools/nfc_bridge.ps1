param(
    [int]$Port = 8765,
    [switch]$Once
)

$ErrorActionPreference = 'Stop'

if (-not ('NfcCard' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class NfcCard {
    public const uint ScopeUser = 0;
    public const uint ShareShared = 2;
    public const uint ProtocolTx = 3;
    public const uint LeaveCard = 0;

    [DllImport("winscard.dll")]
    public static extern int SCardEstablishContext(uint dwScope, IntPtr reserved1, IntPtr reserved2, out IntPtr phContext);

    [DllImport("winscard.dll")]
    public static extern int SCardReleaseContext(IntPtr hContext);

    [DllImport("winscard.dll", CharSet = CharSet.Unicode)]
    public static extern int SCardListReaders(IntPtr hContext, string mszGroups, char[] mszReaders, ref int pcchReaders);

    [DllImport("winscard.dll", CharSet = CharSet.Unicode)]
    public static extern int SCardConnect(IntPtr hContext, string szReader, uint dwShareMode, uint dwPreferredProtocols, out IntPtr phCard, out uint pdwActiveProtocol);

    [DllImport("winscard.dll")]
    public static extern int SCardDisconnect(IntPtr hCard, uint dwDisposition);

    [DllImport("winscard.dll")]
    public static extern int SCardTransmit(IntPtr hCard, IntPtr pioSendPci, byte[] pbSendBuffer, int cbSendLength, IntPtr pioRecvPci, byte[] pbRecvBuffer, ref int pcbRecvLength);

    [StructLayout(LayoutKind.Sequential)]
    public struct IoRequest {
        public uint Protocol;
        public uint PciLength;
    }
}
'@
}

function Get-ReaderName([IntPtr]$Context) {
    $size = 0
    $code = [NfcCard]::SCardListReaders($Context, $null, $null, [ref]$size)
    if ($code -ne 0) {
        throw 'No NFC reader is connected. Plug in the ACR122U.'
    }
    $buffer = New-Object char[] $size
    $code = [NfcCard]::SCardListReaders($Context, $null, $buffer, [ref]$size)
    if ($code -ne 0) {
        throw "The NFC reader list could not be read."
    }
    $names = ((-join $buffer).Split([char]0) | Where-Object { $_ -and $_.Trim() })
    $preferred = $names | Where-Object { $_ -match 'ACR122|PICC|NFC' } | Select-Object -First 1
    if ($preferred) { return $preferred }
    return $names | Select-Object -First 1
}

function Invoke-Apdu([IntPtr]$Card, [uint32]$Protocol, [byte[]]$Command) {
    $pci = New-Object NfcCard+IoRequest
    $pci.Protocol = $Protocol
    $pci.PciLength = 8
    $sendPci = [Runtime.InteropServices.Marshal]::AllocHGlobal(8)
    $recv = New-Object byte[] 260
    $recvLength = $recv.Length
    try {
        [Runtime.InteropServices.Marshal]::StructureToPtr($pci, $sendPci, $false)
        $code = [NfcCard]::SCardTransmit($Card, $sendPci, $Command, $Command.Length, [IntPtr]::Zero, $recv, [ref]$recvLength)
        if ($code -ne 0 -or $recvLength -lt 2) {
            throw "The sticker did not answer."
        }
        $data = New-Object byte[] ($recvLength - 2)
        [Array]::Copy($recv, $data, $data.Length)
        $sw1 = [int]$recv[$recvLength - 2]
        $sw2 = [int]$recv[$recvLength - 1]
        $sw = ($sw1 -shl 8) -bor $sw2
        if ($sw -ne 0x9000) {
            $shown = [BitConverter]::ToString($recv, 0, $recvLength)
            throw "The sticker rejected the read ($('{0:X4}' -f $sw) $shown)."
        }
        return $data
    } finally {
        [Runtime.InteropServices.Marshal]::FreeHGlobal($sendPci)
    }
}

function Get-NfcSnapshot {
    $context = [IntPtr]::Zero
    $card = [IntPtr]::Zero
    try {
        $code = [NfcCard]::SCardEstablishContext([NfcCard]::ScopeUser, [IntPtr]::Zero, [IntPtr]::Zero, [ref]$context)
        if ($code -ne 0) {
            return @{ ok = $false; present = $false; error = 'The NFC service on this PC is not available.' }
        }
        $reader = Get-ReaderName $context
        if (-not $reader) {
            return @{ ok = $false; present = $false; error = 'No NFC reader is connected.' }
        }
        $protocol = [uint32]0
        $code = [NfcCard]::SCardConnect($context, $reader, [NfcCard]::ShareShared, [NfcCard]::ProtocolTx, [ref]$card, [ref]$protocol)
        if ($code -ne 0) {
            return @{ ok = $true; present = $false; readerName = $reader }
        }
        if ($protocol -eq 0) { $protocol = [uint32]2 }
        $uidBytes = Invoke-Apdu $card $protocol ([byte[]](0xFF, 0xCA, 0x00, 0x00, 0x00))
        $uid = ([BitConverter]::ToString($uidBytes)).Replace('-', '')
        $pages = @()
        for ($page = 0; $page -le 15; $page++) {
            try {
                $block = Invoke-Apdu $card $protocol ([byte[]](0xFF, 0xB0, 0x00, $page, 0x04))
                $pages += ([BitConverter]::ToString($block)).Replace('-', '')
            } catch {
                break
            }
        }
        return @{ ok = $true; present = $true; readerName = $reader; uid = $uid; pages = $pages }
    } catch {
        return @{ ok = $false; present = $false; error = $_.Exception.Message }
    } finally {
        if ($card -ne [IntPtr]::Zero) {
            [NfcCard]::SCardDisconnect($card, [NfcCard]::LeaveCard) | Out-Null
        }
        if ($context -ne [IntPtr]::Zero) {
            [NfcCard]::SCardReleaseContext($context) | Out-Null
        }
    }
}

function Send-Json($Stream, $Snapshot) {
    $json = $Snapshot | ConvertTo-Json -Compress -Depth 4
    $payload = [Text.Encoding]::UTF8.GetBytes($json)
    $header = "HTTP/1.1 200 OK`r`nContent-Type: application/json; charset=utf-8`r`nContent-Length: $($payload.Length)`r`nConnection: close`r`n`r`n"
    $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
    $Stream.Write($headerBytes, 0, $headerBytes.Length)
    $Stream.Write($payload, 0, $payload.Length)
}

if ($Once) {
    Get-NfcSnapshot | ConvertTo-Json -Compress -Depth 4
    exit 0
}

$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Any, $Port)
$listener.Start()
Write-Output "NFC bridge listening on port $Port"

while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
        $stream = $client.GetStream()
        $stream.ReadTimeout = 1500
        $buffer = New-Object byte[] 1024
        try { [void]$stream.Read($buffer, 0, $buffer.Length) } catch {}
        Send-Json $stream (Get-NfcSnapshot)
    } catch {
        Write-Output "Bridge request failed: $($_.Exception.Message)"
    } finally {
        $client.Close()
    }
}
