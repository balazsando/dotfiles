function Get-LocalEnvSecrets {
    param($Path, $User, $Password, $Env)
    $base = "$($env:VAULT_ADDR.TrimEnd('/'))/v1"
    $mount, $rest = $Path -split '/', 2
    $spath = "$rest/$Env"
    $login = Invoke-RestMethod -Method Post -Uri "$base/auth/userpass/login/$User" `
        -ContentType 'application/json' -Body (@{ password = $Password } | ConvertTo-Json)
    $headers = @{ 'X-Vault-Token' = $login.auth.client_token }
    Invoke-RestMethod -Uri "$base/auth/token/lookup-self" -Headers $headers | Out-Null
    try {
        $keys = (Invoke-RestMethod -Uri "$base/$mount/metadata/$($spath)?list=true" -Headers $headers).data.keys |
            Where-Object { -not $_.EndsWith('/') }
    } catch { $keys = $null }
    if (-not $keys) { $keys = @('') }
    foreach ($k in $keys) {
        $p = if ($k) { "$spath/$k" } else { $spath }
        $data = (Invoke-RestMethod -Uri "$base/$mount/data/$p" -Headers $headers).data.data
        foreach ($prop in $data.PSObject.Properties) {
            if ($prop.Name -match '^[A-Za-z_][A-Za-z0-9_]*$') { @{ Name = $prop.Name; Value = [string]$prop.Value } }
        }
    }
}

function localenv {
    param([Parameter(Mandatory)][ValidateSet('test', 'preprod')][string]$e)
    foreach ($v in 'VAULT_ADDR', 'VAULT_PATH', 'VAULT_USER', 'VAULT_PASS',
                   'VAULT_PATH_CONNECTOR', 'VAULT_USER_CONNECTOR', 'VAULT_PASS_CONNECTOR') {
        if (-not (Get-Item "env:$v" -ErrorAction SilentlyContinue)) { Write-Error "localenv: $v is not set"; return }
    }
    $app = Get-LocalEnvSecrets $env:VAULT_PATH $env:VAULT_USER $env:VAULT_PASS $e
    $conn = Get-LocalEnvSecrets $env:VAULT_PATH_CONNECTOR $env:VAULT_USER_CONNECTOR $env:VAULT_PASS_CONNECTOR $e
    $all = [ordered]@{}
    foreach ($s in @($app) + @($conn)) { $all[$s.Name] = $s.Value }
    foreach ($n in $all.Keys) { Set-Item "env:$n" $all[$n] }
    $all.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" } | Set-Content -Encoding utf8NoBOM .env.local
    git check-ignore -q .env.local 2>$null
    if ($LASTEXITCODE -eq 1) { Write-Warning "localenv: $PWD/.env.local is not git-ignored" }
}
