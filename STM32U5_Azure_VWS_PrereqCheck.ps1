<#
******************************************************************************
* @file    STM32U5_AWS_VWS_PrereqCheck.ps1
* @author  MCD Application Team
* @brief   Check the presequists for the AWS FreeRTOS iot-reference-stm32u5
******************************************************************************
 * Copyright (c) 2022 STMicroelectronics.

 * All rights reserved.

 * This software component is licensed by ST under BSD 3-Clause license,
 * the "License"; You may not use this file except in compliance with the
 * License. You may obtain a copy of the License at:
 *                        opensource.org/licenses/BSD-3-Clause
 *
******************************************************************************
#>

$Script_Version = "1.1.1 azure vws 2023"
$copyright      = "Copyright (c) 2022 STMicroelectronics."
$about          = "STM32U5 Azure Virtual Workshop 2023 prerequisite check"
$privacy        = "The script doesn't collect or share any data"

$WS_DATE    = "02/22/23"

$softwares =  @(
    [pscustomobject]@{Name="Python*Core Interpreter";
                      MinVersion=[System.Version]"3.11.1"; 
                      Installer="python-3.11.1-amd64.exe";
                      Argument="/passive InstallAllUsers=1 PrependPath=1 Include_test=0";
                      URL="https://www.python.org/ftp/python/3.11.1/python-3.11.1-amd64.exe";
                      Version="Python --version";
                      check_path=1;}

    [pscustomobject]@{Name="Microsoft Azure CLI";
                      MinVersion=[System.Version]"2.40.0"; 
                      Installer="azure-cli-2.40.0.msi";
                      Argument="/passive";
                      URL="https://azcliprod.blob.core.windows.net/msi/azure-cli-2.40.0.msi";
                      Version="az --version";
                      check_path=1;}

    [pscustomobject]@{Name="STM32CubeProgrammer";
                      MinVersion=[System.Version]"2.12.0"; 
                      Installer="SetupSTM32CubeProgrammer_win64.exe"; 
                      URL="https://www.st.com/content/ccc/resource/technical/software/utility/group0/e4/fa/e0/4f/c4/0e/4b/41/stm32cubeprg-win64-v2-12-0/files/stm32cubeprg-win64-v2-12-0.zip/jcr:content/translations/en.stm32cubeprg-win64-v2-12-0.zip"; 
                      ZIP="en.stm32cubeprg-win64-v2-12-0.zip"
                      check_path=0;}

    [pscustomobject]@{Name="git";
                      MinVersion=[System.Version]"0.0.0";
                      Installer="Git-2.39.0.2-64-bit"; 
                      URL="https://github.com/git-for-windows/git/releases/download/v2.39.0.windows.2/Git-2.39.0.2-64-bit.exe"; 
                      ZIP="";
                      Version="git --version";
                      check_path=1;}                        
)

$downloads = @(
    [pscustomobject]@{Name="STM32CubeExpansion_Cloud_AZURE_V2.1.0";
    Zip="en.x-cube-azure_v2-1-0.zip"
    URL="https://stm32iot.blob.core.windows.net/firmware/en.x-cube-azure_v2-1-0.zip";
    SRC_URL="https://www.st.com/en/embedded-software/x-cube-azure.html#get-software";
    Destination="C:\";}    
)

$PATH_TOOLS = ".\tools"

$ws_tenant_id = "aedf9cbb-56df-47c5-82a7-9a57071cab8e"

<# Check if PC is connected to internet #>
function Internet_Connection_Check()
{
   if(!(Test-Connection -ComputerName www.st.com -Quiet))
   {
    Write-Host "ERROR: You are not connected to Internet. Please connect to Internet then run the script again"  -ForegroundColor Red
    Start-Sleep -Seconds 2
    Exit 1
   }

   Write-Host "OK : Connected to Internet"  -ForegroundColor Green
}

<# Refresh envirement variables #>
function refresh_envirement_variables 
{
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

<# Check the default broswer setting #>
function Browser_Check()
{
    $URL_LINK_DEFULT_SETTING       = "https://support.microsoft.com/en-us/windows/change-your-default-browser-in-windows-020c58c6-7d77-797a-b74e-8f07946c5db6"

    $default_browser = (Get-ItemProperty HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice -Name ProgId).ProgId

    if(!(($default_browser -eq "MSEdgeHTM") -or ($default_browser -eq "ChromeHTML")) )
    {
        
        Write-Host "ERROR : Please set Chrome or Edge as Browswer"   -ForegroundColor Red
        Start-Sleep -Seconds 2
        Start-Process $URL_LINK_DEFULT_SETTING
        Exit 1
    }

    Write-Host "OK : Microsoft Edge or Chrome set as default browswer"  -ForegroundColor Green
}

<# Install Python modules #>
function Python_Modules_Install()
{
    Write-Host "Installing Python libraries"

    & python -m pip install -r requirements.txt
}

<# Install Python #>
function Python_Pip_Check()
{
    $PIP_INSTALLER = "get-pip.py"
    $PIP_URL_LINK  = "https://bootstrap.pypa.io/get-pip.py"

    $pip_version = & python -m pip --version

    if(!$pip_version)
    {
      $pip_installer = "$PATH_TOOLS\$PIP_INSTALLER"

      if (!(Test-Path $pip_installer))
      {
        Write-Host "Downloading pip"
        Import-Module BitsTransfer
        Start-BitsTransfer -Source $PIP_URL_LINK -Destination $pip_installer
      }
    
      Write-Host "Installing pip"
      Start-Process -Wait -FilePath  python -ArgumentList "$pip_installer"

      refresh_envirement_variables
    }
    else 
    {
        Write-Host "OK : Pip installed"  -ForegroundColor Green
    }
}

function Get-SoftwareInfo($program)
{
	$InstalledSoftware = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ | Get-ItemProperty)

	IF (Test-path HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\) 
    {
		$InstalledSoftware += (Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ | Get-ItemProperty)
	}

	IF (Test-path HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\) 
    {
	    $InstalledSoftware += (Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ | Get-ItemProperty) 
    }
	
    return ($InstalledSoftware | Where-Object {$_.DisplayName -like '*'+$program+'*'}) | Select-Object -Property  DisplayName, DisplayVersion
}

function Get-SoftwareInstaller($software)
{
    if($software.ZIP)
    {
        $zip_file =  $PATH_TOOLS+"\"+$software.ZIP

        if (!(Test-Path $zip_file))
        {
            Write-Host "Downloading : "$software.ZIP
            Invoke-WebRequest $software.URL -OutFile $zip_file
        }

        $installer = "$PATH_TOOLS\"+$software.Installer

        if (!(Test-Path $installer))
        {
            Write-Host "Extracting : " $software.ZIP
            Expand-Archive "$zip_file" "$PATH_TOOLS"
        }
    }
    else
    {
        $installer = "$PATH_TOOLS\"+$software.Installer

        if (!(Test-Path $installer))
        {
          Write-Host "Downloading : "$software.Installer
          Invoke-WebRequest $software.URL -OutFile $installer
        }
    }

    Write-Host "Installing : " $software.Installer

    if($software.Argument)
    {
       Start-Process -Wait -FilePath  $installer $software.Argument
    }
    else
    {
        Start-Process -Wait -FilePath  $installer
    }

    # Refresh envirement variables
    refresh_envirement_variables
}

<# Install AZCLI extensions #>
function AZCLI_Extensions_Install()
{
    Write-Output "Installing AZ extensions"

    try 
    {
        & az extension add --name azure-iot 
        & az extension update --name azure-iot
        & az extension add --name account
        & az extension update --name account
    }
    catch
    {
        Write-Host "ERROR: Azure Command Line Extension Install Fail" -ForegroundColor Red
        Exit 1
    }
}

function AZCLI_Login_Check()
{
    if ($WS_DATE -eq (Get-Date -UFormat "%m/%d/%y")) {

        Write-Output "Redirecting to a browser window to log in to Azure"
        Start-Sleep -Seconds 1

        Write-Output "Use the credential from  credentials.txt to log in to Azure"
        Write-Output "credentials.txt will automatically open in 3 seconds"
        Write-Output "Please return to the terminal after you login to Azure"

        Start-Sleep -Seconds 3
        
        & notepad ".\scripts\credentials.txt"

        Start-Sleep -Seconds 3

        & az logout

        $login_info = & az login |  Out-String| ConvertFrom-Json

        if($login_info.tenantId -eq $ws_tenant_id)
        {
            Write-Host "OK : Azure Command Line Login Successful"  -ForegroundColor Green
        }
        else 
        {
            Write-Host "ERROR: Azure Login Failed" -ForegroundColor Red
            Exit 1
        }

        Write-Host "Configuring JSON File"  -ForegroundColor Yellow
        & python .\scripts\configureJson.py
    }
}

<#######################################################  

                     Script start 

########################################################>
Clear-Host

Write-Host "Script version: $Script_Version"  -ForegroundColor Green
Write-Host "$copyright"
Write-Host "$about"
Write-Host "$privacy"

# Refresh envirement variables
refresh_envirement_variables

# Check if connected to Internet
Internet_Connection_Check

# Check if default browser is Edge or Chrome
Browser_Check

# Create tools dir
If(!(test-path -PathType container $PATH_TOOLS))
{
    New-Item -ItemType Directory -Path $PATH_TOOLS
}

# Check required software tools
foreach($software in $softwares)
{
    $version = Get-SoftwareInfo $software.Name

    if($null -eq $version)
    {
        Write-Host $software.Name not installed  -ForegroundColor Yellow

        Get-SoftwareInstaller $software
    }

    if($version.Count)
    {
        Write-Host "ERROR: Multiple versions of " $software.Name " instelled"  -ForegroundColor Red
    }

    foreach($v in $version)
    {
        $sv = [System.Version]$v.DisplayVersion

        if($software.MinVersion -le $sv)
        {
            Write-Host "OK :" $v.DisplayName : $sv -ForegroundColor Green
            
            if($software.check_path)
            {
              $cmd = $software.Version
              $version = $cmd

              if(!$version)
              {
                  Write-Host "ERROR: " $v.DisplayName " not added to path"  -ForegroundColor Red
                  Write-Host "Please uninstall " $v.DisplayName " and run the script again"  -ForegroundColor Red
                  Exit 1
              }

              Write-Host "OK : " $v.DisplayName " added to path"  -ForegroundColor Green
            }
        }
        else 
        {
            Write-Host "ERROR: " $v.DisplayName : $sv ". Please uninstall " $v.DisplayName " and run the script again" -ForegroundColor Red
            
            Exit 1
        }
    }
}

# Check if pip is installed
Python_Pip_Check

# Install Python modules
Python_Modules_Install

# Install Azure CLI Extensions
AZCLI_Extensions_Install

# Clone the repos
foreach($download in $downloads)
{
    $PATH_FIRMWARE= $download.Destination+$download.Name
    $PATH_DOWNLOAD=  $PATH_TOOLS+"\"+$download.Zip

    if (!(Test-Path -Path "$PATH_FIRMWARE"))
    {
        if (!(Test-Path -Path "$PATH_DOWNLOAD")) 
        {
            Write-Host "Downloading " $download.Name  -ForegroundColor Yellow
            Invoke-WebRequest $download.URL -OutFile $PATH_DOWNLOAD
        }
        
        if (Test-Path -Path "$PATH_DOWNLOAD") 
        {
            Write-Host "Extracting " $download.Name " to " $download.destination -ForegroundColor Yellow
            Expand-Archive "$PATH_DOWNLOAD"  -DestinationPath $download.destination
        }
        else 
        {
            Write-Host "ERROR: " $download.Name " Download ERROR. Please downlaod the file manually, and extract to your C: drive." -ForegroundColor Red
            Start-Process $download.SRC_URL
            Exit 1
        }
    }
    else 
    {
        Write-Host "OK : " $download.Name  -ForegroundColor Green
    }   
}

#Attempt to login and check credentials
AZCLI_Login_Check

Write-Host "OK : System check successful !"  -ForegroundColor Green

Exit 0
