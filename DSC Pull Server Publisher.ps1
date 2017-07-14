<#
Automatically convert Powershell modules into zips for DSC pull server to be ready for deployment.
Copies MOF files into the pull server config dir and gives the checksum files.
#>

#This function will take in user input and based on their descision, produce a properly named zip file for DSC pull server deployment.
function select-zipdeploy ($modname)
{

    $modpath = "C:\Program Files\WindowsPowerShell\Modules\$modname"

    #Takes input from user to choose to deploy the specified module.
    $Option = Read-Host -Prompt ($modname + ': Would you like to zip ' + $modname + ' for deployment? Enter <y or n>')
    
    #if they say yes the folder (contains version number) will be read and produce a zip of the module using the format <ModuleName>_<Version>.
    if ($Option -eq "y") {

    #Generates the file name structure.
    $zippedmod = $modname + "_" + (dir $modpath -Name) + ".zip"

    #This will produce the zipped module file for deployment and save it in the pullservers module folder.
    Add-Type -A System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($modpath, "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\" + $zippedmod)
    Write-Host "Added " $zippedmod " to C:\LocalDepot for deployment"
    }

    #If the user enters n it will skip the module in question.
    elseif ($Option -eq "n") {Write-Host ("Skipped " + $modname)}

    #This will loop back incase of user typos in the input.
    else {
            Write-Host -foregroundcolor red "Option is invalid"
            select-zipdeploy ($modname)
          }
}

#This function will make a copy of the mof file into the pullclient config dir and create a checksum
function mofdeploy ($mof, $Location) {

    #Defines each mof files full location
    $moffile = ($Location + '\' + $mof)

    #Defines new location for the mof
    $newmof = ("$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration\" + $mof)

    #compies the mof file into the pull configs fir
    cp $moffile $newmof -force -verbose 
}


#Runs a foreach loop to initate the selection function to deploy modules.
function deploy-modules {
    
    #Pulls a list of modules installed into powershell.
    $modlist = dir 'C:\Program Files\WindowsPowerShell\Modules' -Name

    #Loops through each installed powershell module.
    foreach ($modname in $modlist) 
    {
        select-zipdeploy ($modname)
    }
}

#Function to initiate the deployment of all configs in the specified location.
function deploy-configs {
   
    #Converts the location input into a string to pass through windows dir.
    $Location = Read-Host -Prompt ('Please enter the full directory of your mof files. Example: C:\user\syseng\Documents\moffiles')
    
    #Filters all files in the given directory to only mof files.
    $moflist = dir $Location -Name | select-string '.mof'

    #Error checking for dir with no mof files.
    if ($moflist -eq $null) {
        Write-Host -foregroundcolor red "No mof files found in the specified folder. Please check your input and try again"
        deploy-configs
        }

    #Loop to copy each mof inot the pull server config dir.
    foreach ($mof in $moflist)
    {
        mofdeploy $mof $Location
    }

    #Creates the checksum for each mof file in the pullservers dir 
    New-DscChecksum "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration\" -force -verbose
}

#This function is used to select what you want to deploy to the pull server
function select-script {

    #Takes user input to determine which funtions to run.
    $Option = Read-Host -Prompt ('Type "m" to deploy modules, "c" to deploy configurations, or "b" for both')

    #list of statements to run each funtion or functions dpeneding on the option entered.
    if ($Option -eq "m") {deploy-modules}
    elseif ($option -eq "c") {deploy-configs}
    elseif ($Option -eq "b") {
        deploy-modules
        deploy-configs
    }

    #Error checking input.
    else {
        Write-host -foregroundcolor red "Your selection was invalid"
        select-script
    }
}

select-script
