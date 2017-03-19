
<span class="notice">Drop-ins can be copied and pasted into the PageEditor</span>
<br />
<table>
    <# IF dropins.NUM_ROWS < 1 #><tr><td></td></tr><tr><td>There are no dropins enabled.</td></tr><# ELSE #>
    <# LOOP dropins #><tr>
        <td><a href="<# uri #>" target="_blank"><img src="<# thumb #>" /><br /><# uri #></a></td>
        <td>Added by <a href="/Users?srch=<# email #>" target="_blank"><# displayName #></a><br />
            <a href="mailto:<# email #>"><# email #></a><br /><# addedDate #></td>
        <td><input type="button" value="Delete" onclick="deleteMedia(<# id #>);" /></td>
    </tr><# ENDLOOP #><# ENDIF #>
</table>

