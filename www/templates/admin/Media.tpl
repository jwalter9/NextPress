
<table>
    <# LOOP media #><tr>
        <td><a href="<# uri #>" target="_blank"><img src="<# thumb #>" /><br /><# uri #></a></td>
        <td>Added by <a href="/Users?srch=<# email #>" target="_blank"><# displayName #></a><br />
            <a href="mailto:<# email #>"><# email #></a><br /><# addedDate #></td>
        <td><input type="button" value="Delete" onclick="deleteMedia(<# id #>);" /></td>
    </tr><# ENDLOOP #>
</table>

