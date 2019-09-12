# use TLS 1.2 (see bug 1443595)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# capture env
Get-ChildItem Env: | Out-File "C:\install_env.txt"

# needed for making http requests
$client = New-Object system.net.WebClient
$shell = new-object -com shell.application

# utility function to download a zip file and extract it
function Expand-ZIPFile($file, $destination, $url)
{
    $client.DownloadFile($url, $file)
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items())
    {
        $shell.Namespace($destination).copyhere($item)
    }
}

# allow powershell scripts to run
Set-ExecutionPolicy Unrestricted -Force -Scope Process

# install June 2010 DirectX SDK for compatibility with Win XP
$client.DownloadFile("http://download.microsoft.com/download/A/E/7/AE743F1F-632B-4809-87A9-AA1BB3458E31/DXSDK_Jun10.exe", "C:\DXSDK_Jun10.exe")

# prerequisite for June 2010 DirectX SDK is to install ".NET Framework 3.5 (includes .NET 2.0 and 3.0)"
Install-WindowsFeature NET-Framework-Core

# now run DirectX SDK installer
Start-Process C:\DXSDK_Jun10.exe -ArgumentList "/U" -wait -NoNewWindow -PassThru -RedirectStandardOutput C:\directx_sdk_install.log -RedirectStandardError C:\directx_sdk_install.err

# initial clone of mozilla-central
# Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "C:\mozilla-build\python\Scripts\hg clone -u null https://hg.mozilla.org/mozilla-central C:\gecko" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\hg_initial_clone.log" -RedirectStandardError "C:\hg_initial_clone.err"

# download Windows Server 2003 Resource Kit Tools
$client.DownloadFile("https://download.microsoft.com/download/8/e/c/8ec3a7d8-05b4-440a-a71e-ca3ee25fe057/rktools.exe", "C:\rktools.exe")

# download gvim
$client.DownloadFile("http://artfiles.org/vim.org/pc/gvim80-069.exe", "C:\gvim80-069.exe")

# https://bugzil.la/1274844 download BinScope
$client.DownloadFile("https://download.microsoft.com/download/2/6/A/26AAA1DE-D060-4246-93B5-7D7C877E4F8F/BinScopeSetup.msi", "C:\BinScopeSetup.msi")

# install BinScope
Start-Process "msiexec" -ArgumentList "/i C:\BinScopeSetup.msi /quiet" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\binscope-install.log" -RedirectStandardError "C:\binscope-install.err"

# open up firewall for livelog (both PUT and GET interfaces)
New-NetFirewallRule -DisplayName "Allow livelog PUT requests" -Direction Inbound -LocalPort 60022 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Allow livelog GET requests" -Direction Inbound -LocalPort 60023 -Protocol TCP -Action Allow

# install go (not required, but useful)
md "C:\gopath"
Expand-ZIPFile -File "C:\go1.11.5.windows-amd64.zip" -Destination "C:\" -Url "https://storage.googleapis.com/golang/go1.11.5.windows-amd64.zip"

# install PSTools
# md "C:\PSTools"
# Expand-ZIPFile -File "C:\PSTools\PSTools.zip" -Destination "C:\PSTools" -Url "https://download.sysinternals.com/files/PSTools.zip"

# install git
$client.DownloadFile("https://github.com/git-for-windows/git/releases/download/v2.16.2.windows.1/Git-2.16.2-64-bit.exe", "C:\Git-2.16.2-64-bit.exe")
Start-Process "C:\Git-2.16.2-64-bit.exe" -ArgumentList "/SILENT" -Wait -PassThru

# install AZCopy (azure table storage backup utility - for bstack)
$client.DownloadFile("http://aka.ms/downloadazcopy", "C:\AZCopy.msi")
Start-Process "msiexec" -ArgumentList "/i C:\AZCopy.msi /quiet" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\AZCopy-install.log" -RedirectStandardError "C:\AZCopy-install.err"

# install node
$client.DownloadFile("https://nodejs.org/dist/v6.6.0/node-v6.6.0-x64.msi", "C:\NodeSetup.msi")
Start-Process "msiexec" -ArgumentList "/i C:\NodeSetup.msi /quiet" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\node-install.log" -RedirectStandardError "C:\node-install.err"

# set permanent env vars
[Environment]::SetEnvironmentVariable("GOROOT", "C:\go", "Machine")
[Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";C:\Program Files\Vim\vim80;C:\go\bin;C:\gopath\bin;C:\mozilla-build\python;C:\mozilla-build\python\Scripts;C:\Program Files\Git\cmd;C:\Program Files\nodejs", "Machine")
[Environment]::SetEnvironmentVariable("GOPATH", "C:\gopath", "Machine")

# upgrade python libraries
Start-Process "C:\mozilla-build\python\python.exe" -ArgumentList "-m pip install --upgrade pip==8.1.1 setuptools==20.7.0 virtualenv==15.0.3 wheel==0.29.0 pypiwin32==219 requests==2.9.1 psutil==4.1.0" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\python_package_upgrades.log" -RedirectStandardError "C:\python_package_upgrades.err"

# set env vars for the currently running process
$env:GOROOT = "C:\go"
$env:GOPATH = "C:\gopath"
$env:PATH   = $env:PATH + ";C:\go\bin;C:\gopath\bin;C:\mozilla-build\python;C:\mozilla-build\python\Scripts;C:\Program Files\Git\cmd"

# get generic-worker and livelog source code (note required, but useful)
Start-Process "go" -ArgumentList "get -t github.com/taskcluster/generic-worker github.com/taskcluster/livelog" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\generic-worker\go-get_install.log" -RedirectStandardError "C:\generic-worker\go-get_install.err"

# generate ed25519 key
Start-Process C:\generic-worker\generic-worker.exe -ArgumentList "new-ed25519-keypair --file C:\generic-worker\generic-worker-ed25519-signing-key.key" -Wait -NoNewWindow -PassThru -RedirectStandardOutput C:\generic-worker\generate-signing-key.log -RedirectStandardError C:\generic-worker\generate-signing-key.err

# download cygwin (not required, but useful)
$client.DownloadFile("https://www.cygwin.com/setup-x86_64.exe", "C:\cygwin-setup-x86_64.exe")

# install cygwin
# complete package list: https://cygwin.com/packages/package_list.html
Start-Process "C:\cygwin-setup-x86_64.exe" -ArgumentList "--quiet-mode --wait --root C:\cygwin --site http://cygwin.mirror.constant.com --packages openssh,vim,curl,tar,wget,zip,unzip,diffutils,bzr" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\cygwin_install.log" -RedirectStandardError "C:\cygwin_install.err"

# open up firewall for ssh daemon
New-NetFirewallRule -DisplayName "Allow SSH inbound" -Direction Inbound -LocalPort 22 -Protocol TCP -Action Allow

# workaround for https://www.cygwin.com/ml/cygwin/2015-10/msg00036.html
# see:
#   1) https://www.cygwin.com/ml/cygwin/2015-10/msg00038.html
#   2) https://cygwin.com/git/gitweb.cgi?p=cygwin-csih.git;a=blob;f=cygwin-service-installation-helper.sh;h=10ab4fb6d47803c9ffabdde51923fc2c3f0496bb;hb=7ca191bebb52ae414bb2a2e37ef22d94f2658dc7#l2884
$env:LOGONSERVER = "\\" + $env:COMPUTERNAME

# configure sshd (not required, but useful)
Start-Process "C:\cygwin\bin\bash.exe" -ArgumentList "--login -c `"ssh-host-config -y -c 'ntsec mintty' -u 'cygwinsshd' -w 'qwe123QWE!@#'`"" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\cygrunsrv.log" -RedirectStandardError "C:\cygrunsrv.err"

# start sshd
Start-Process "net" -ArgumentList "start sshd" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\net_start_sshd.log" -RedirectStandardError "C:\net_start_sshd.err"

# download bash setup script
$client.DownloadFile("https://raw.githubusercontent.com/petemoore/myscrapbook/master/setup.sh", "C:\cygwin\home\Administrator\setup.sh")

# run bash setup script
Start-Process "C:\cygwin\bin\bash.exe" -ArgumentList "--login -c 'chmod a+x setup.sh; ./setup.sh'" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\Administrator_cygwin_setup.log" -RedirectStandardError "C:\Administrator_cygwin_setup.err"

# install dependencywalker (useful utility for troubleshooting, not required)
md "C:\DependencyWalker"
Expand-ZIPFile -File "C:\depends22_x64.zip" -Destination "C:\DependencyWalker" -Url "http://dependencywalker.com/depends22_x64.zip"

# install ProcessExplorer (useful utility for troubleshooting, not required)
md "C:\ProcessExplorer"
Expand-ZIPFile -File "C:\ProcessExplorer.zip" -Destination "C:\ProcessExplorer" -Url "https://download.sysinternals.com/files/ProcessExplorer.zip"

# install ProcessMonitor (useful utility for troubleshooting, not required)
md "C:\ProcessMonitor"
Expand-ZIPFile -File "C:\ProcessMonitor.zip" -Destination "C:\ProcessMonitor" -Url "https://download.sysinternals.com/files/ProcessMonitor.zip"
