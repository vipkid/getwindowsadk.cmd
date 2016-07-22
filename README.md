# getwindowsadk
Script to silently download and install features of the Windows 10 Assessment and Deployment Kit (ADK)

## Usage

Launch this as local administrator. By default it will download the adbksetup.exe and all missing packages to the working dir %SYSTEMDRIVE%\adksetup, install from there the features DeploymentTools and WindowsPreinstallationEnvironment, backup the downloaded files to the launch dir and at the end remove the work dir.

Tested with Windows 7 Pro SP1 x64 de_DE and Windows 7 Ultimate SP1 x86 zh-TW


## Download
https://developer.microsoft.com/en-us/windows/hardware/windows-assessment-deployment-kit
