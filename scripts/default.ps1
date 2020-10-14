$path = ".\export\text.txt"
New-Item $path
$username = $args[0]
$password = $args[1]
Set-Content $path $username+$password
