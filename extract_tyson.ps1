param(
    [Parameter(Mandatory = $true)]
    [string]$DatabasePath,
    [string]$OutputPath = (Join-Path $PSScriptRoot 'data\tyson-invoice-lines.csv')
)

$ErrorActionPreference = 'Stop'
$database = (Resolve-Path -LiteralPath $DatabasePath).ProviderPath
$output = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
if (Test-Path -LiteralPath $output) {
    throw 'The output path already exists. Choose a different OutputPath.'
}

$settings = [System.Data.Odbc.OdbcConnectionStringBuilder]::new()
$settings.Driver = 'Microsoft Access Driver (*.mdb, *.accdb)'
$settings['DBQ'] = $database
$settings['ReadOnly'] = '1'
$connection = [System.Data.Odbc.OdbcConnection]::new($settings.ConnectionString)
$culture = [System.Globalization.CultureInfo]::InvariantCulture

try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = 'SELECT * FROM INVOICE_FACT WHERE INVOICE_DAY_KEY BETWEEN 827045 AND 827047'
    $reader = $command.ExecuteReader()
    try {
        $columns = for ($i = 0; $i -lt $reader.FieldCount; $i++) { $reader.GetName($i) }
        $rows = @(
            while ($reader.Read()) {
                $record = [ordered]@{}
                for ($i = 0; $i -lt $columns.Count; $i++) {
                    $value = $reader.GetValue($i)
                    $record[$columns[$i]] = if ($value -is [DBNull]) { $null }
                    elseif ($value -is [double] -or $value -is [single]) { $value.ToString('R', $culture) }
                    elseif ($value -is [System.IFormattable]) { $value.ToString($null, $culture) }
                    else { [string]$value }
                }
                [pscustomobject]$record
            }
        )
    } finally {
        $reader.Dispose()
        $command.Dispose()
    }
} finally {
    $connection.Dispose()
}

$customers = @($rows.CUSTOMER_KEY | Where-Object { $_ -ne $null } | Sort-Object -Unique).Count
if ($rows.Count -ne 17440 -or $customers -ne 6029) {
    throw "The expected teaching-case sample has 17,440 invoice lines and 6,029 distinct customers. Found $($rows.Count) lines and $customers customers."
}

[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($output)) | Out-Null
$rows | Export-Csv -LiteralPath $output -NoTypeInformation -Encoding UTF8
Write-Output "Extracted $($rows.Count) invoice lines and $customers distinct customers."
