set

# sysprep prepares for snapshoting windows AMIs
# https://aws.amazon.com/premiumsupport/knowledge-center/sysprep-create-install-ec2-windows-amis/
C:/ProgramData/Amazon/EC2-Windows/Launch/Scripts/InitializeInstance.ps1 -Schedule
C:/ProgramData/Amazon/EC2-Windows/Launch/Scripts/SysprepInstance.ps1 -NoShutdown
