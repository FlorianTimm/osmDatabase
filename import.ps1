cd E:\osmDatabase\
Get-Content "config.ini" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }
wget https://download.geofabrik.de/europe/germany/hamburg-latest.osm.pbf -O working\hamburg-latest.osm.pbf
$env:PGPASSWORD = $h.Get_Item("Password");
osm2pgsql\osm2pgsql -s --hstore-all --prefix hamburg --extra-attributes -d $h.Get_Item("Database") -P $h.Get_Item("Port") -U $h.Get_Item("User") -S $h.Get_Item("Style") --keep-coastlines working\hamburg-latest.osm.pbf
wget https://download.geofabrik.de/europe/germany/hamburg-updates/state.txt -O working\state.txt

&"C:\Program Files\PostgreSQL\11\bin\psql.exe" @("-U", $h.Get_Item("User"), "-p", $h.Get_Item("Port"), "-f", "views.sql", $h.Get_Item("Database"))