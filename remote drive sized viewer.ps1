

Get-WmiObject Win32_logicaldisk -ComputerName DESKTOP-2BJ7HJE `
| Format-Table DeviceID, `
@{Name="Drive Size(GB)";Expression={[decimal]("{0:N0}" -f($_.size/1gb))}}, `
@{Name="Drive Free Space(GB)";Expression={[decimal]("{0:N0}" -f($_.freespace/1gb))}}, `
@{Name="Drive Free pct";Expression={"{0,6:P0}" -f(($_.freespace/1gb) / ($_.size/1gb))}} `
-AutoSize