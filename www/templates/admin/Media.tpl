
<span class="notice">Files here can be copied and pasted into the PageEditor or ArticleEditor</span>
<br />
<table>
    <# IF media.NUM_ROWS < 1 #><tr><td></td></tr><tr><td>There are no files uploaded.</td></tr>
        <tr><td>Upload files using the Page or Article editor.</td></tr><# ELSE #>
    <# LOOP media #><tr>
        <td><a href="<# uri #>" target="_blank"><img src="<# thumb #>" /><br /><# uri #></a></td>
        <td>Added by <a href="/Users?srch=<# email #>" target="_blank"><# displayName #></a><br />
            <a href="mailto:<# email #>"><# email #></a><br /><# addedDate #></td>
        <td><input type="button" value="Delete" onclick="deleteMedia(<# id #>);" /></td>
    </tr><# ENDLOOP #><# ENDIF #>
</table>

