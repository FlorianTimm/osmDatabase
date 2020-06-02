cd E:\osmDatabase\
Get-Content "config.ini" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }
$env:PGPASSWORD = $h.Get_Item("Password");

osmosis\bin\osmosis.bat --read-replication-interval workingDirectory="working" --simplify-change --write-xml-change - | osm2pgsql\osm2pgsql --append -s -d $h.Get_Item("Database") -P $h.Get_Item("Port") --prefix hamburg --extra-attributes -U $h.Get_Item("User") -S $h.Get_Item("Style") --hstore-all --keep-coastlines -r xml -

&"C:\Program Files\PostgreSQL\11\bin\psql.exe" @("-U", $h.Get_Item("User"), "-p", $h.Get_Item("Port"), "-f", "views.sql", $h.Get_Item("Database"))