[CmdletBinding()]
param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [int]$numPwd = 5,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [int]$numWords = 2,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [int]$numSpcl = 3
)

$filePath = "$PSScriptRoot\IndexedWords.txt"

#region password policies
<#
    Password Policies:
    Banking:  8-32 alpha numeric + special characters
    Investment Broker: 6-20 alpha-numeric-special characters excluding "#&*<>[]'{}
                       32 alpha numeric + special characters
                       "  #  &  '  *  <  >  [  ]  {   }
    exclude chars:     34,35,8,39,42,60,62,91,93,123,125 
    
    Additional excludes: (  )  +  ,  -  .  `
                         40,41,43,44,45,46,96  
#>
#endregion

$filePath
Clear-Host

#region functions 
function randomSpecialChar
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        $numSpcl
    )

    #region random special character (ascii decimal 33..47)
    # 33,36..37,40..47,63..64,94..95
    # $digits = 33..47 | Get-Random -Count $numSpcl    

    ### random digits & spl chars with exclusions: @(,33 + 36..37 + 40..59 + 63..64 + ,92 + 94..96)
    #endregion
    
    $digits = $null
    $specialCharArr = $null

    # $digits = @(,33 + 36..37 + 40..59 + 63..64 + ,92 + 94..96) | Get-Random -Count $numSpcl    
    ###-> bug: 3-consecutive digits missing special character(s)
    $digits = @(,33 + 36..37 + ,42 + 47..59 + 63..64 + ,92 + 94..95) | Get-Random -Count $numSpcl

    foreach ( $digit in $digits )
    {
        $specialCharArr += [char]$digit
    }

    return [string]$($specialCharArr -join "")
} # end randomSpecialChar

function randomWords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [int] $numWords
    )

    # load array of indexed words in memory
    $indexedWords = Get-Content -LiteralPath $filePath # 'C:\Users\alex0\OneDrive\Documents\WindowsPowerShell\Scripts\CompoundWords\IndexedWords.txt'

    # loop through each [$numPwd] to create (n) random words
    for($k=1; $k -le $numPwd; $k++) {

        # roll virtual dice and pick [$numWords] random words
        $wordArr = @()
        $wordCounter = 1

        do {
            $index = $(for($i=1; $i -le 5; $i++) {
                Get-Random -min 1 -max 6
            }) -join ''

            $wordArr += $(($indexedWords -match $index) -split "`t")[1]
            $wordCounter++
        } While($wordCounter -le $numWords)
    }
    
    return $wordArr
}

function randomUpperCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [array] $wordArr
    )

    $newWordArr = @()

    $wordArr | ForEach-Object {

        $str = $null = $_.ToString()
        # $str
        
        # convert random character(s) to uppercase 
        # ([int] $($wordArr[$i].length/3))

        $numUpperCase = [int] $(($_.Length)/3)
        
        $ucIndex = 0..$(($_.Length)-1) | Get-Random -Count $numUpperCase | Sort-Object

        # convert these indexes to uppercase
        Write-Debug $($ucIndex -join '').ToString()

        ##################################
        ### build dynamic if condition ###
        ##################################

        $scriptBlock = "`$("        

        # loop through each $ucIndex and build scriptblock

        $counter = 1

        foreach($index in $ucIndex) {
            if($counter -le $(($ucIndex.Count)-1))
            {
                $scriptBlock += "(`$i -ne $index) -and "
            }
            else
            {
                $scriptBlock += "(`$i -ne $index)"
            }

            $counter++
        }

        $scriptBlock += ")"

        $scriptBlock = [scriptblock]::Create($scriptBlock)

        # convert random character(s) to uppercase 
        $newStr = $null
        for($i=0; $i -le $(($str.Length)-1); $i++) {

            # Write-Host $scriptBlock
            # "`$i = {0}" -f $i    

            if( Invoke-Command -ScriptBlock $scriptBlock ) 
            {
                $newStr += $str[$i]
                # $newStr -join ''
            }
            else
            {
                $newStr += $str[$i].ToString().ToUpper()
                # $newStr -join ''
            }
        }

        # Write-Host $newStr
        # $($newStr -join '').ToString()

        $newWordArr += $(,$newStr)

        Write-Debug $($newStr -join '').ToString()
        Write-Debug "`r"
    }

    # return $($newStr -join '').ToString()
    return $newWordArr
}
#endregion functions

for($i=1; $i -le $numPwd; $i++) {

    $separator = $(randomSpecialChar -numSpcl $numSpcl)
    $passPhrase = $( randomUpperCase -wordArr $(randomWords  -numWords $numWords) )

    $($passPhrase -join " $separator ")

    # $passPhrase = $($passPhrase -join " $separator ")
    # "{0} chars random passphrase: {1}`r" -f $(($passPhrase.length)), $($passPhrase)

}

"`r"
