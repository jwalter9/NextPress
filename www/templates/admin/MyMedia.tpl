
<span class="notice">Files here can be copied and pasted into the PageEditor or ArticleEditor</span>
<br />
<table>
    <# IF media.NUM_ROWS < 1 #><tr><td></td></tr><tr><td>There are no files uploaded.</td></tr>
        <tr><td>Upload files using the Page or Article editor.</td></tr><# ELSE #>
    <# LOOP media #><tr>
        <td><a href="<# uri #>" target="_blank"><img src="<# thumb #>" /></a></td>
        <td><# uri #></td>
        <td><# addedDate #></td>
    </tr><# ENDLOOP #><# ENDIF #>
</table>

