<# 


███████╗███╗   ███╗███████╗██╗     ██╗     
██╔════╝████╗ ████║██╔════╝██║     ██║     
███████╗██╔████╔██║█████╗  ██║     ██║     
╚════██║██║╚██╔╝██║██╔══╝  ██║     ██║     
███████║██║ ╚═╝ ██║███████╗███████╗███████╗
╚══════╝╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
                                           

.SYNOPSIS 

Script para obtener lo basico de un forense 

.DESCRIPTION

Ejecuta:

.\smell.ps1 (para ver por pantalla)
.\smell.ps1 | Export-csv -Append -path artifacts.csv (para ver por pantalla y guardar el resultado)
 

#> 

Param(
    [string]$ComputerName,
    [switch]$Remote,

    [switch]$CSV 
)


function param1{
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False)]
   [string]$ComputerName,
    
   [switch]$Remote,

   [switch]$CSV
)
}


if ($Remote=$False){
    $Session = New-PSSession -ComputerName $ComputerName -Credential (Get-Credential) -UseSSL 
    $FileContents = Get-Content -Path ($PSSCriptRoot+"\smell.ps1")
    Invoke-Command -Session $Session -ScriptBlock {
        param($FilePath,$data)
        Set-Content -Path $FilePath -Value $data
    } -ArgumentList "C:\Windows\smell.ps1",$FileContents
    Invoke-Command -Session $Session -ScriptBlock{'C:\Windows\smell.ps1'}
}

else{

clear


write-host " "
write-host " "
write-host "  ____ _  _ ____ _    _     " -ForegroundColor green -BackgroundColor black
write-host "  [__  |\/| |___ |    |     " -ForegroundColor green -BackgroundColor black
write-host "  ___] |  | |___ |___ |___  " -ForegroundColor green -BackgroundColor black
write-host "                            " -ForegroundColor green -BackgroundColor black                        
write-host " "

Write-Progress -Activity "Fecha y hora"

# Fecha y hora

$dateObj = New-Object PSObject

$date = Get-Date #Fecha y hora del sistema
$timezone = Get-TimeZone #PC timezone
$PCUptime = (get-date) - (gcim Win32_OperatingSystem).LastBootUpTime #PC Encendido 

$dateObj | Add-Member Current_Date_Time $date 
$dateObj | Add-Member TimeZone $timezone
$dateObj | Add-Member PC_Uptime_hours $PCUptime

write-host "##########################################################"
write-host "INFORMACION DE FECHA Y HORA:  "
write-host ($dateObj | format-list | Out-String) 


# Información del SO

Write-Progress -Activity "Sistema operativo"

$OSobj = New-Object PSObject #OS object

$TypicalName = gwmi win32_operatingsystem | % caption #Nombre windows
$FullVer = [System.Environment]::OSVersion.Version  #versión

$OSobj | Add-Member TypicalName $TypicalName
$OSobj | Add-Member Major_Minor_Build_Revision $FullVer

write-host "##########################################################"
write-host "INFORMACION DEL SO: " 
Write-host ($OSobj | Format-list |  Out-String)


#HARDWARE

$HardwareObj =  New-Object PSObject #info del sistema

$cpuname = gwmi win32_processor | % name #procesador y velocidad
$RAM =  gwmi win32_physicalmemoryarray | % maxcapacity
$ramGB = $RAM/1MB
$HDD = gwmi win32_diskdrive | % size 


 
$AllDrives = gdr -PSProvider FileSystem | % Name
$logicalDrives = gwmi win32_logicalDisk | % VolumeName


$HardwareObj | Add-Member CPU_Brand_Type $cpuname
$HardwareObj | Add-Member RAM_AmountGB $ramGB
$HardwareObj | Add-Member HDD_AmountGB $hddGB
$HardwareObj | Add-Member Drives $AllDrives
$Hardwareobj | Add-Member MountPoints $logicalDrives


write-host "##########################################################"

write-host "INFORMACION DEL SISTEMA Y HARDWARE:"
write-host ($HardwareObj | format-list| out-string)

##########################################################

#Dominio

Write-Progress -Activity "Dominio"

$DomainObj = New-Object PSobject # Dominio

#informacion del equipo

$hostname = gwmi win32_computersystem | ft Name, Domain


write-host "##########################################################"
write-host "INFORMACION DEL EQUIPO Y DOMINIO:"
write-host ($hostname |out-string)

##########################################################

#usuarios 

Write-Progress -Activity "Usuarios"

$SID = gwmi win32_useraccount | ft Name, SID 

write-host "##########################################################"
write-host "USUARIOS: " 

write-host ($SID | format-list | Out-String)

##########################################################
#inicio

Write-Progress -Activity "Persistencia"

$services = get-service | where {$_.starttype -eq 'Automatic'} | ft Name, DisplayName 
$Programs = Get-Ciminstance win32_startupcommand | ft Name,command, user, Location

write-host "##########################################################"
write-host "SERVICIOS DE INICIO: "
write-host ($services | format-list | out-string )
write-host "PROGRAMAS QUE SE INICIAN AL ENCENDIDO:" 
write-host ($Programs | format-list| out-string) 



#tareas
$Tasks = Get-Scheduledtask | where {$_.State -eq 'Ready'} | ft TaskName

write-host "TAREAS : "
write-host ($Tasks| fl| out-string)



#red

Write-Progress -Activity "Redes"

$arptable = arp -a 
$macaddress = getmac 
$route = Get-NetRoute
$IP = Get-NetIPAddress | ft IPAddress, InterfaceAlias
$dhcp = Get-WmiObject Win32_NetworkAdapterConfiguration | ? {$_.DHCPEnabled -eq $true -and $_.DHCPServer -ne $null} | select DHCPServer
$DNSservers = Get-DnsClientServerAddress | select-object -ExpandProperty Serveraddresses
$gatewayIPv4 = Get-NetIPConfiguration | % IPv4defaultgateway | fl nexthop
$gatewayIPv6 = Get-NetIPConfiguration | % IPv46defaultgateway | fl nexthop
$listeningports = Get-NetTCPConnection -State Listen | ft State, localport, ElemenetName, LocalAddress, RemoteAddress #listening ports
$tcpconnections = Get-NetTCPConnection | where {$_.State -ne "Listen"} | ft creationtime,LocalPort,LocalAddress,remoteaddress,owningprocess, state
$DNScache = Get-DnsClientCache | ft 
$nwshares = get-smbshare
$printers = Get-Printer
$wifi = netsh.exe wlan show profiles 

write-host "#########################################################"
write-host "INFORMACION DE RED: "
write-host " " 
write-host "ARP : " 
write-host ($arptable| format-list | out-string)

write-host " " 
write-host "Direcciones MAC: " 
Write-host ($macaddress| fl| out-string)
write-host "Tabla de rutas: " 
write-host ($route| out-string) 
write-host "IPs: "
write-host ($IP|fl|out-string)

write-host ($dhcp|ft| out-string)  

write-host "DNS"
write-host "--------------------"
write-host ($DNSservers | ft| out-string)

write-host "PuertaEnlaceIPv4:"
write-host ($gatewayIPv4 |fl| out-string)
write-host "PuertaEnlaceIPv6:"
write-host ($gatewayIPv6 |fl| out-string)

write-host "Lista de puertos:"
write-host ($listeningports | fl| out-string)

write-host "Conexiones establecidas: " 
write-host ($tcpconnections | out-string)

write-host "DNS cache :" 

write-host ($DNScache | out-string)


write-host "Red compartida: " 
write-host ($nwshares | out-string)


write-host "Impresoras: "
write-host ($printers | out-string)  


write-host "Perfiles Wifi:" 
write-host ($wifi | fl | out-string) 


#Programas 

Write-Progress -Activity "Aplicaciones"

$prog = gwmi win32_product | ft

write-host "#########################################################"
write-host "PROGRAMAS INSTALADOS : "
write-host ($prog | fl | out-string)


#Procesos

Write-Progress -Activity "Procesos"

$processes = get-process | ft processname,id,path,owner

write-host "#########################################################"
write-host "PROCESOS : "
write-host ($processes | Out-String)

write-host "Process Tree :" 
Function Show-ProcessTree
{
    Function Get-ProcessTree($proc,$depth=1)
    {
        $process | Where-Object {$_.ParentProcessId -eq $proc.ProcessID -and $_.ParentProcessId -ne 0} | ForEach-Object {
            "{0}|--{1} pid={2} ppid={3}" -f (" "*3*$depth),$_.Name,$_.ProcessID,$_.ParentProcessId
            Get-ProcessTree $_ (++$depth)
            $depth--
        }
    }

    $filter = {-not (Get-Process -Id $_.ParentProcessId -ErrorAction SilentlyContinue) -or $_.ParentProcessId -eq 0}
    $process = gwmi Win32_Process
    $top = $process | Where-Object $filter | Sort-Object ProcessID
    foreach ($proc in $top)
    {
        "{0} pid={1}" -f $proc.Name, $proc.ProcessID
        Get-ProcessTree $proc
    }
}

Show-ProcessTree

#Drivers 

Write-Progress -Activity "Controladores"

$driver = Get-WmiObject Win32_PnPSignedDriver| ft devicename, driverversion,installdate,location
write-host "#########################################################"
write-host "DRIVER informacion : "
write-host($driver|ft|out-string)


#Descargas y documentos (proximamente)

write-host "#########################################################"

read-host "Pulsa enter para salir:"
}