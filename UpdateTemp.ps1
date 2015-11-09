##############################################################
#
# Requires ADO.NET Driver for MySQL (Connector/NET) 
# http://dev.mysql.com/downloads/connector/net/
#
# Requires custom eventlog on computer, can use this command to create:
# New-EventLog -LogName Application -Source "TempDB"
#
# Requires Database on mariadb or mysql
# Can be created with TempDB.sql
#
# Requires Functions for Vera
# Author:  Markus Jakobsson (www.automatiserar.se)
# Vera.ps1 in the same directory as the script
#
# Jimmy Lind
#
##############################################################
##############################################################

# static variables
$rootpath = "C:\EAC\Script"


# Editable variables
$global:MaxChangetoAllow = 40 #Maximum temperature change before ignoring the data
$global:MaxChangeBetweenUpdates = 4 #Maximum change between updates

$Debug = $false
$verboselogging = $false

$MySQLAdminUserName = ''
$MySQLAdminPassword = ''
$MySQLDatabase = 'TempDB'
$MySQLHost = ''

$EventlogSource = "TempDB"
$EventlogName = "Application"

#Set Root path for the scripts
cd $rootpath

# Import functions for Vera
. .\Vera.ps1




# Function to write to mysql/mariadb
Function Query-Mysql{ 
    Param(
    [Parameter(
    Mandatory = $true,
    ParameterSetName = '',
    ValueFromPipeline = $true)]
    [string]$Query
    )

    $ConnectionString = "server=" + $MySQLHost + ";port=3306;uid=" + $MySQLAdminUserName + ";pwd=" + $MySQLAdminPassword + ";database="+$MySQLDatabase

    Try {
        [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
        $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
        $Connection.ConnectionString = $ConnectionString
        $Connection.Open()

        $Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
        $DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
        $DataSet = New-Object System.Data.DataSet
        $RecordCount = $dataAdapter.Fill($dataSet, "data")
        $DataSet.Tables[0]
      }

    Catch {
        Write-Host "ERROR : Unable to run query : $query `n$Error[0]"
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EntryType Error -EventId 20 -Message "ERROR : Unable to run query : $query `n$Error[0]"
    }

    Finally {
        $Connection.Close()
    }
}

#Function to update Roomnames from vera
#Just run update-TempRoomName
function Update-TempRoomName()
{
    foreach($Tempsensor in $veraTempSensors)
    {
        "$($Tempsensor.Room),$($Tempsensor.RoomID)" | write-host
        $Query = "UPDATE RoomIndex
        SET RoomName='$($Tempsensor.Room)'
        Where RoomID='$($Tempsensor.RoomID)'"

        Query-Mysql -Query $Query
    }
}

#Function to update sensorname from vera
#Just run update-TempSensorName
function Update-TempSensorName()
{
    foreach($Tempsensor in $veraTempSensors)
    {
        "$($Tempsensor.Name),$($Tempsensor.EnhetsID)" | write-host
        $Query = "UPDATE SensorIndex
        SET SensorName='$($Tempsensor.name)'
        Where SensorID='$($Tempsensor.EnhetsID)'"

        Query-Mysql -Query $Query
    }
}



#Function to update TempDB
Function update-Temp($sensorID, $Temperature,$Room)
{

    #Sql query, gets the last tempdata from DB with $sensorID, within last hour.
    #If there is no last tempdata within last hour it doesnt care about MaxChangeBetweenUpdates variable.
    $query = "Select * from SensorData
    where Sensor=$sensorID and
    Timestamp > NOW() - INTERVAL 1 HOUR
    Order by Number Desc
    Limit 1"

    #runs query
    $CurrentTempInDB = Query-Mysql -Query $query

    #Check if Temp change is more then Max then exit
    If($Temperature-$CurrentTempInDB.Temp -gt $global:MaxChangetoAllow -or $CurrentTempInDB.Temp-$Temperature -gt $global:MaxChangetoAllow)
    {
        if($verboselogging)
        {
            Write-EventLog -LogName $EventlogName -Source $EventlogSource -EntryType Information -EventId 30 -Message "cannot log to DB, temperature($($CurrentTempInDB) to $($Temperature)) change more then maxChangeToAllow $Global:maxChangeToAllow" 
        }
        Write-host "cannot log to DB, temperature change more then maxChangeToAllow"   
    }
    Else
    {

    #Checks if the change from before is more then MaxChangeBetweenUpdates minus and plus.
    #if it is change $TemperatureToWrite to MaxChangeBetweenUpdates
    $TemperatureToWrite=$Temperature
    If($CurrentTempInDB){
        If($TemperatureToWrite-$CurrentTempInDB.Temp -gt $global:MaxChangeBetweenUpdates)
        {
            $TemperatureToWrite=$CurrentTempInDB.Temp+$global:MaxChangeBetweenUpdates
            if($verboselogging)
            {
                Write-EventLog -LogName $EventlogName -Source $EventlogSource -EntryType Information -EventId 31 -Message "Did only write $global:MaxChangeBetweenUpdates change, MaxChangeBetweenUpdates whas resolved" 
            }
            write-host "Did only write $global:MaxChangeBetweenUpdates change, MaxChangeBetweenUpdates whas resolved"
        }
        Elseif($CurrentTempInDB.Temp-$TemperatureToWrite -gt $global:MaxChangeBetweenUpdates)
        {
            $TemperatureToWrite=$CurrentTempInDB.Temp-$global:MaxChangeBetweenUpdates
            if($verboselogging)
            {
                Write-EventLog -LogName $EventlogName -Source $EventlogSource -EntryType Information -EventId 32 -Message "Did only write minus $global:MaxChangeBetweenUpdates change, MaxChangeBetweenUpdates whas resolved" 
            }
            write-host "Did only write minus $global:MaxChangeBetweenUpdates change, MaxChangeBetweenUpdates whas resolved"
        }

    }

        if($debug)
        {
            Write-EventLog -LogName $EventlogName -Source $EventlogSource -EntryType Information -EventId 33 -Message "INSERT INTO SensorData (Sensor,Temp) VALUES ('$sensorID','$TemperatureToWrite');"
        }
        write-host "INSERT INTO SensorData (Sensor,Temp) VALUES ('$sensorID','$TemperatureToWrite');"
        
        #Query to update Temp in TempDB
        Query-Mysql -Query "INSERT INTO SensorData (Sensor,Temp,RoomID) VALUES ('$sensorID','$TemperatureToWrite','$Room');"

    }
}

#
#  Get all ID for Temp
#
[array]$veraTempSensors = get-MJ-VeraStatus -veraIP 192.168.2.161 | ?{$_.EnhetsTyp -like "Temperaturgivare"}


######################################
#  Gammal kod för att ta it ID
##############################################################
#$veraAllStatus | ?{$_.EnhetsTyp -like "Temperaturgivare"} | ft EnhetsID, name, roomid, CurrentTemperature
#[array]$allTempIDs = $veraAllStatus | ?{$_.EnhetsTyp -like "Temperaturgivare"} | %{$_.EnhetsID}
#[array]$allTempIDs = 30,31,32,50,51,52,82,85,97
##############################################################


#Main script
#
#For each Tempsensor
foreach($Tempsensor in $veraTempSensors)
{
    #Get All rooms from DB
    $Rooms = Query-Mysql -Query "Select * FROM RoomIndex"

    #Get all sensors from DB
    $sensors = Query-Mysql -Query "Select * FROM SensorIndex"

    #If sensor doesnt exists in DB, create one
    If($sensors.SensorID -notcontains $Tempsensor.EnhetsID)
    {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EntryType Information -EventId 34 -Message "Adding sensor, ID $($Tempsensor.EnhetsID)"
        write-host "Adding sensor, ID $($Tempsensor.EnhetsID)"
        $Query = "INSERT INTO SensorIndex (SensorID,SensorName) VALUES ('$($Tempsensor.EnhetsID)','$($Tempsensor.Name)')"
        Query-Mysql -Query $Query
    }
    

    #If room doesnt exists in DB, create one
    If($Rooms.RoomID -notcontains $Tempsensor.RoomID)
    {

        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EntryType Information -EventId 35 -Message write-host "Adding room, ID $($Tempsensor.RoomID)"
        write-host "Adding room, ID $($Tempsensor.RoomID)"
        $Query = "INSERT INTO RoomIndex (RoomID,RoomName) VALUES ('$($Tempsensor.RoomID)','$($Tempsensor.Room)')"
        Query-Mysql -Query $Query
    }
    
    #Update temp
    if($debug)
    {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EntryType Information -EventId 36 -Message "Update-Temp -sensorID $($Tempsensor.EnhetsID) -Temperature $($Tempsensor.CurrentTemperature) -Room $($Tempsensor.RoomID)"
    }
    Update-Temp -sensorID $Tempsensor.EnhetsID -Temperature $Tempsensor.CurrentTemperature -Room $Tempsensor.RoomID
}
