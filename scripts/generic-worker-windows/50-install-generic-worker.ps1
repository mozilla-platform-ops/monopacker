# allow powershell scripts to run
Set-ExecutionPolicy Unrestricted -Force -Scope Process

# needed for making http requests
$client = New-Object system.net.WebClient

# install nssm
Expand-ZIPFile -File "C:\nssm-2.24.zip" -Destination "C:\" -Url "http://www.nssm.cc/release/nssm-2.24.zip"

# download generic-worker
md C:\generic-worker
$client.DownloadFile("https://github.com/taskcluster/generic-worker/releases/download/v15.1.5/generic-worker-multiuser-windows-amd64.exe", "C:\generic-worker\generic-worker.exe")

# download livelog
$client.DownloadFile("https://github.com/taskcluster/livelog/releases/download/v1.1.0/livelog-windows-amd64.exe", "C:\generic-worker\livelog.exe")

# install generic-worker
Start-Process C:\generic-worker\generic-worker.exe -ArgumentList "install service --configure-for-aws --nssm C:\nssm-2.24\win64\nssm.exe --config C:\generic-worker\generic-worker.config" -Wait -NoNewWindow -PassThru -RedirectStandardOutput C:\generic-worker\install.log -RedirectStandardError C:\generic-worker\install.err
# Start-Process C:\generic-worker\generic-worker.exe -ArgumentList "install startup --config C:\generic-worker\generic-worker.config" -Wait -NoNewWindow -PassThru -RedirectStandardOutput C:\generic-worker\install.log -RedirectStandardError C:\generic-worker\install.err
