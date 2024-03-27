####################################################################
#                                                                  #
# For readme, go to https://github.com/Mihaly7/HCI.Eventreader/    #
#                                                                  #
####################################################################

Function New-Hashtable

### Create hashtable for Get-Winevent filtering

{
Param
    (
    [Parameter(Mandatory=$false)]
        [string]$hLogname = $null,
        [array]$hEventId = $null,
        [array]$hProviderName = $null,
        [string]$hDate = (get-date -format "MM/dd/yyyy"),
        [string]$hTime = (get-date -format "HH:mm:ss"),
        [string]$hDuration  = "1",
        [bool]$hBackwards = $true,
        [string]$hLogpath = $null



    )

# Date and time conversion
$StartTime = $hDate+" "+$hTime | Get-Date

If ($hBackwards -ne $false)
    {
    $M = "-"
    }
Else
    {
    $M = $null
    }

#Duration calculator

If ($hDuration -like "*:*")
    {
    $CDuration = $hDuration.split(':')
    $endTime = ($StartTime).AddSeconds(($m+(new-timespan -hour $CDuration[0] -Minutes $CDuration[1] -Seconds $CDuration[2]).TotalSeconds).tostring())
    }

Else
    {
    $endTime = ($StartTime).Addhours($m+($hDuration).tostring())
    }

#$Backward Check

If ($hbackwards -eq $true)
    {
    $sTime = $endTime
    $eTime = $StartTime
    }
Else
    {
    $sTime = $StartTime
    $eTime = $endTime
    }



$hFilter = @{Starttime = $sTime; Endtime = $eTime};

#adding parameters
    If ($hLogname -ne $null)
        {
        $hFilter = $hFilter+@{LogName = $hLogname};
        }
    If ($hLogpath -ne $null)
        {
        $hFilter = $hFilter+@{Path= $hLogpath};
        }
    If ($hEventId -ne $null)
        {
        $hFilter = $hFilter+@{ID= $hEventID}
        }
    If ($hProviderName -ne $null)
        {
        $hFilter = $hFilter+@{ProviderName= $hProviderName}
        }



#End
return $hfilter
    }
<#
.SYNOPSIS
Get eventlog entries from an SDDC dataset (https://aka.ms/s2ddiag) or its node in filtered format

.DESCRIPTION
Get-SDDCevents read various eventlogs (which can be read with get-winevent) from an SDDC dataset

.PARAMETER Logname
Name of the log, wildcards can be used ("*")

.PARAMETER Cluster
Name of the cluster

.PARAMETER ClusterNodes
Name of the clusternodes. Use "," as separator

.PARAMETER Message
Filter for event message, wildcards can be used ("*")

.PARAMETER EventId
EventID filtering. Use "," as separator

.PARAMETER FilterInformation
Filter out informational events, disabled by default. (1 or 0)

.PARAMETER ProviderName
Event provider name filter.

.PARAMETER Backwards
Go back in time.

.PARAMETER Date
Date of start. Format must be MM/dd/yyyy.

.PARAMETER Time
Time of start. Format must be HH/mm/ss.

.PARAMETER Duration
Time window of the events, can be hours (single digit) or specified time (hh:mm:ss)

.PARAMETER Detailed
Output will be in format-list format, disabled by default

.EXAMPLE
Checking system log in sddc on january 1st 2024 on all nodes from 2 hours before 10:00 AM
Get-SDDCEvents -path C:\temp\info-cluster-202401011555 -logname system -date 01/01/2024 -time 00:10:00 -backwards 1 -duration 2

.NOTES
General notes
#>
Function Get-SDDCevents

{

    param
    (
    [Parameter(Mandatory=$true)]
        [string]$Logfile = (Read-Host "Logname (* for wildcard)"),
        [string]$Date = (Read-Host  "Start date (format should be MM/DD/YYYY)"),
        [string]$Time = (Read-Host "Start time (HH:MM:SS)"),
        [string]$Duration  = (Read-Host  "Duration (HH:MM:SS)"),

    [Parameter(Mandatory=$false)]
        [string]$Path = (Get-Location).path,
        [string]$Message = $null,
        [array]$EventId = $null,
        [bool]$FilterInformation = $false,
        [array]$ProviderName = $null,
        [bool]$Backwards = $false,
        [string]$logname = $null,
        [bool]$Detailed = $false

    )

# Gather evtx files
$Evtxfiles = Get-ChildItem -path $path -filter "$Logname*" -Include *.evtx -Recurse



# Default event level: Informational included
# Information level filter
$maxlevel = 4

if ($Filterinformation -eq $true)
    {
        [int]$maxlevel = 3
    }
else
    {
        Write-host "All events included" -ForegroundColor Yellow
    }# Read logs

$Evtxfiles = Get-ChildItem -path $path -filter "*$logfile*" -Include *.evtx -Recurse

#create Hashtable




# Read logs

    foreach($Evtxfile in $Evtxfiles)
    {

# Show actual log file

    ((Get-WinEvent -Path $Evtxfile.FullName -MaxEvents 10 ) | Where-Object machinename -ne $null | Select-Object Machinename,logname)[0]

    Write-Host "Log location: $Evtxfile `n" -ForegroundColor Yellow


# Read log
            $filter = New-Hashtable -hLogname $logfile -hLogpath $evtxfile.fullname -hDate $date -hTime $time -hDuration $Duration -hEventId $EventId -hProviderName $ProviderName -hBackwards $Backwards -ErrorAction SilentlyContinue

            $output =  Get-winevent -FilterHashtable $Filter -ErrorAction SilentlyContinue  | Where-Object {$_.Level -gt 0 -and $_.Level -le $maxlevel}



# Write log entries to host

        if ($detailed -ne $false)
            {
            $output | Sort-Object TimeCreated | Format-List Timecreated,Providername,Id,Leveldisplayname,Message
            }
        else
            {
            $output | Sort-Object TimeCreated | Format-Table Timecreated,Providername,Id,Leveldisplayname,Message -Wrap
            }
    }
 }



<#
.SYNOPSIS
Get eventlog entries from a cluster or its node in filtered format

.DESCRIPTION
Get-ClusterOSevents read various eventlogs (which can be read with get-winevent) from a cluster or remote computers

.PARAMETER Logname
Name of the log, wildcards can be used ("*")

.PARAMETER Cluster
Name of the cluster

.PARAMETER ClusterNodes
Name of the clusternodes. Use "," as separator

.PARAMETER Message
Filter for event message, wildcards can be used ("*")

.PARAMETER EventId
EventID filtering. Use "," as separator

.PARAMETER FilterInformation
Filter out informational events, disabled by default. (1 or 0)

.PARAMETER ProviderName
Event provider name filter.

.PARAMETER Backwards
Go back in time.

.PARAMETER Date
Date of start. Format must be MM/dd/yyyy.

.PARAMETER Time
Time of start. Format must be HH/mm/ss.

.PARAMETER Duration
Time window of the events, can be hours (single digit) or specified time (hh:mm:ss)

.PARAMETER Detailed
Output will be in format-list format, disabled by default

.EXAMPLE
Checking 2 clusternodes's logs contains the word "smbclient" on 01/10/2024 between 17:00 and 20:00
Get-AZHCIClusterEvents -ClusterNodes strhci03,strhci02 -Logname *smbclient* -FilterInformation 0 -Date 01/10/2024 -time 17:00:00 -Duration 3

.NOTES
General notes
#>
Function Get-ClusterOSEvents
    {
        param
        (
        [Parameter(Mandatory=$true)]
            [string]$Logname = (Read-Host "Logname (* for wildcard)"),
        [Parameter(Mandatory=$false)]
            $Cluster = (Get-Cluster -ErrorAction SilentlyContinue),
            $ClusterNodes = $null,
            [string]$Message = $null,
            [array]$EventId = $null,
            [bool]$FilterInformation = $false,
            [array]$ProviderName = $null,
            [bool]$Backwards = $true,
            [string]$Date = (get-date -format "MM/dd/yyyy"),
            [string]$Time = (get-date -format "HH:mm:ss"),
            [string]$Duration  = "1",
            [bool]$Detailed = $false,
            $ExportPath = $null
        )

#create Hashtable
$filter = New-Hashtable -hLogname $logname -hDate $date -hTime $time -hDuration $Duration -hEventId $EventId -hProviderName $ProviderName -hBackwards $Backwards -ErrorAction SilentlyContinue

Write-Host "Used filters:" -ForegroundColor Yellow
$filter


# Default event level: Informational included
# Information level filter
$maxlevel = 4

if ($Filterinformation -eq $true)
    {
        [int]$maxlevel = 3
    }
else
    {
        Write-host "All events included" -ForegroundColor Yellow
    }


#start event reading

    foreach ($ClusterNode in $ClusterNodes)
        {
            Write-host "$clusternode's $logname log" -ForegroundColor Yellow




# Read log
    $output =  Get-winevent -ComputerName $ClusterNode -FilterHashtable $Filter | Where-Object {$_.Level -gt 0 -and $_.Level -le $maxlevel}


# Write log entries to host
        if ($detailed -ne $false)
            {
            $output | Sort-Object TimeCreated | Format-List Timecreated,Providername,Id,Leveldisplayname,Message
            }
        else
            {
            $output | Sort-Object TimeCreated | Format-Table Timecreated,Providername,Id,Leveldisplayname,Message
            }

#Export filtered events to XML
            if ($ExportPath -ne $null)
            {
                $filedate = (get-date -Format mmddyyyy_hhmmss).tostring()
                [string]$filename = "$ClusterNode_$logname_$filedate_.xml"
                $XMLpath = (Get-Location -Path $ExportPath) + "\" + $filename
                $output | Export-Clixml -Path $filename

            }

        }

#collect xml files and compress them to given path ($exportpath)
        if ($ExportPath -ne $null)
        {
            $XMLfiles = Get-ChildItem -Path $ExportPath -Filter "*.xml" | Where-Object {$_.CreationTime -gt (get-date).AddMinutes(-5)}
            Compress-Archive -Path $XMLfiles -DestinationPath $ExportPath\$filename.zip -Force
        }

    }

