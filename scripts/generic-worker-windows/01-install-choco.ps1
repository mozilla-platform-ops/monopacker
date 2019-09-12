# allow powershell scripts to run
Set-ExecutionPolicy Bypass -Scope Process -Force

# install chocolatey package manager
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# install Windows SDK 8.1
choco install -y windows-sdk-8.1
