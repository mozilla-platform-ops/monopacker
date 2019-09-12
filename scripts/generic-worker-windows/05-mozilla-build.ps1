# allow powershell scripts to run
Set-ExecutionPolicy Unrestricted -Force -Scope Process

# needed for making http requests
$client = New-Object system.net.WebClient

# install rustc dependencies (32 bit)
$client.DownloadFile("http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe", "C:\vcredist_x86-vs2013.exe")
Start-Process "C:\vcredist_x86-vs2013.exe" -ArgumentList "/install /passive /norestart /log C:\vcredist_x86-vs2013-install.log" -Wait -PassThru

# install rustc dependencies (64 bit)
$client.DownloadFile("http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe", "C:\vcredist_x64-vs2013.exe")
Start-Process "C:\vcredist_x64-vs2013.exe" -ArgumentList "/install /passive /norestart /log C:\vcredist_x64-vs2013-install.log" -Wait -PassThru

# install more rustc dependencies (32 bit)
$client.DownloadFile("http://download.microsoft.com/download/f/3/9/f39b30ec-f8ef-4ba3-8cb4-e301fcf0e0aa/vc_redist.x86.exe", "C:\vcredist_x86-vs2015.exe")
Start-Process "C:\vcredist_x86-vs2015.exe" -ArgumentList "/install /passive /norestart /log C:\vcredist_x86-vs2015-install.log" -Wait -PassThru

# install more rustc dependencies (64 bit)
$client.DownloadFile("http://download.microsoft.com/download/4/c/b/4cbd5757-0dd4-43a7-bac0-2a492cedbacb/vc_redist.x64.exe", "C:\vcredist_x64-vs2015.exe")
Start-Process "C:\vcredist_x64-vs2015.exe" -ArgumentList "/install /passive /norestart /log C:\vcredist_x64-vs2015-install.log" -Wait -PassThru

# install mozilla-build yasm dependencies (32 bit)
$client.DownloadFile("http://download.microsoft.com/download/C/6/D/C6D0FD4E-9E53-4897-9B91-836EBA2AACD3/vcredist_x86.exe", "C:\vcredist_x86-vs2010.exe")
Start-Process "C:\vcredist_x86-vs2010.exe" -ArgumentList "/install /passive /norestart /log C:\vcredist_x86-vs2010-install.log" -Wait -PassThru

# install mozilla-build yasm dependencies (64 bit)
$client.DownloadFile("http://download.microsoft.com/download/A/8/0/A80747C3-41BD-45DF-B505-E9710D2744E0/vcredist_x64.exe", "C:\vcredist_x64-vs2010.exe")
Start-Process "C:\vcredist_x64-vs2010.exe" -ArgumentList "/install /passive /norestart /log C:\vcredist_x64-vs2010-install.log" -Wait -PassThru

# download mozilla-build installer
$client.DownloadFile("https://ftp.mozilla.org/pub/mozilla.org/mozilla/libraries/win32/MozillaBuildSetup-Latest.exe", "C:\MozillaBuildSetup.exe")

# run mozilla-build installer in silent (/S) mode
Start-Process "C:\MozillaBuildSetup.exe" -ArgumentList "/S" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\MozillaBuild_install.log" -RedirectStandardError "C:\MozillaBuild_install.err"

# Create C:\builds and give full access to all users (for hg-shared, tooltool_cache, etc)
md "C:\builds"
$acl = Get-Acl -Path "C:\builds"
$ace = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","Full","ContainerInherit,ObjectInherit","None","Allow")
$acl.AddAccessRule($ace)
Set-Acl "C:\builds" $acl

# download tooltool
$client.DownloadFile("https://raw.githubusercontent.com/mozilla/release-services/master/src/tooltool/client/tooltool.py", "C:\builds\tooltool.py")
