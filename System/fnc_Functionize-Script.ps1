Function Functionize-Script {

    <#
    .SYNOPSIS
        Function to create a function from a PowerShell script's content ("function-ize" a script.)

    .DESCRIPTION
        Function to create a function from a PowerShell script's content.

        WARNING: This script does not check if the specified script contains a function.  If this occurs, the resulting new function will not work, since calling the function simply loads the nested function.

    .PARAMETER ScriptPath
        The path to the PS1 script file.  This file should be an executing script as opposed to a script that loads a function.

    .PARAMETER FunctionName
        The desired name of the function.  If omitted, the base file name of the script will be used.

    .PARAMETER Force
        Overwrites any existing loaded function of the same name.
    #>
    
    [CmdletBinding()]
    
    Param(
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeLine=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-Path $_})]
        [Alias("Path")]
        [String[]]$ScriptPath,

        [Parameter(Position=1,Mandatory=$false)]
        [Alias("Name")]
        [String]$FunctionName,

        [Switch]$Force
    )
   
    #Check if the function call was dot-sourced.
    #Voided: setting Global scope seems to have eliminated this need.
    #If ($MyInvocation.InvocationName -ne '.') {Write-Warning "You must dot-source the command.  Prefix the command with a single period and space:`n. $($MyInvocation.Line)";Break}

#TODO
    

    BEGIN {} #End BEGIN

    PROCESS {
        ForEach ($xScriptPath in $ScriptPath) {
            $FilePath = Resolve-Path -Path $xScriptPath -ErrorAction Stop | Select-Object -ExpandProperty Path
            Try {
                $ScriptObj = Get-Item -Path $FilePath -ErrorAction Stop
                If ($ScriptObj.Extension -ne '.PS1') {
                    Write-Warning "$Path is not a PowerShell script file."
                    Break
                } #End If

                #If input is from Pipeline or -FunctionName was not specified...
                If (($MyInvocation.ExpectingInput -eq $true) -or (-Not $PSBoundParameters['FunctionName'])) {
                    #Get the FunctionName from the Script File Name
                    If (-Not $PSBoundParameters['FunctionName']) {
                        $FunctionName = $ScriptObj.BaseName 
                    }#End If
                } Else {
                    #Otherwise, use the value specifed in the -FunctionName parameter
                    #nothing to do here, since $FunctionName is already set
                } #End If..Else

                #Create the definition
                [String]$ScriptContent = ''
                Get-Content -Path $FilePath | ForEach {
                    $ScriptContent += ("$_" + "`n")
                } #End ForEach

                #Create the function
                Write-Verbose "Creating function: $FunctionName"
                $SplatParams = @{
                    Path  = "Function:\"
                    Name  = "Global:$FunctionName"
                    Value = $ScriptContent
                } #End Splat

                If ($PSBoundParameters['Force']) {
                    $SplatParams += @{Force = $true}
                } #End If

                $Result = New-Item @SplatParams -ErrorAction Stop 
                $Result | Select-Object -Property Name,Verb,Noun,Description,CommandType,DefaultParameterSet,Version,Options,HelpFile,HelpUri,Source,Parameters,ParameterSets
            } Catch {
                    Write-Warning $_.Exception.Message
            } #End Try..Catch
        } #End ForEach
    } #End PROCESS

    END {}#End END

} #End Function

New-Alias -Name ConvertTo-Function -Value Functionize-Script -Force