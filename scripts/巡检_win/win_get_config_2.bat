@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

set OS_type=Windows
set OS_version=

REM for HA
set is_HA=
set duble_host=null

REM get systeminfo
for /f "tokens=*" %%f in ('wmic OS Get Csname /value ^| find "="') do set %%f
set host_name=%CSName%
for /f " tokens=1,2* delims=. " %%i in ("%host_name%") do set host_name=%%i

for /f "tokens=*" %%f in ('wmic OS Get Caption /value ^| find "="') do set %%f
set OS_info=%Caption%

for /f "tokens=*" %%f in ('wmic OS Get Version /value ^| find "="') do set %%f
set OS_version=!OS_info!%Version%

REM get middleware HA
for /f "tokens=*" %%j in ('sc query ^| findstr /I "ClusSvc"') do (set c=!c!%%j)
if defined c (
   set is_HA=true
  cluster node | findstr /v "^--" | findstr /v "节点"| findstr /v /i "Status" | findstr /v "状态" | findstr /v "^$">C:\ClusNodeInfo.txt
  for /f "tokens=1,2,3" %%a in (C:\ClusNodeInfo.txt) do (
    set ver=%%a
        if !duble_host! == null (
      set duble_host=!ver!
    ) else (
          set duble_host=!duble_host!;!ver!
    )
  )
) else (
  set is_HA=false
)

for /f "delims=" %%i in ('hostname') do set i=%%i

echo @SysType@
wmic csproduct get Vendor,Name,IdentifyingNumber /value
echo os_type=!OS_type!
echo os_version=!OS_version!
echo is_ha=!is_HA!
echo host_name=%i%
echo @end@

::gateway
echo @gateway@
echo gateway=
wmic path Win32_NetworkAdapterConfiguration where IPEnabled=TRUE get 'DefaultIPGateway' 2>nul | more +1
echo @end@

::os
echo @os@
wmic os get 'LastBootUpTime','InstallDate' /value 2>nul
wmic path win32_timezone get 'Caption' /value 2>nul
echo @end@

::NtpServer
echo @NtpServer@
For /f "tokens=1,2,3,4,*" %%i in ('Reg Query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"^|findstr "NtpServer"') do echo NtpServer=%%k
echo @end@

::dns
echo @dns@
echo dns=
wmic path Win32_NetworkAdapterConfiguration where IPEnabled=TRUE get 'DNSServerSearchOrder' 2>nul | more +1
echo @end@
