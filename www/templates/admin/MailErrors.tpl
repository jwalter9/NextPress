
<table id="err-table">
<# IF mail_errors.NUM_ROWS > 0 #>
    <tr><th>Date &amp; Time</th><th>Error</th></tr>
    <# LOOP mail_errors #><tr>
        <td><# formatDate #></td>
        <td><# errors #></td>
    </tr><# ENDLOOP #>
    <tr><td colspan=2 align=right><a href="/ClearMailErrors">Clear All</a></td></tr>
<# ELSE #>
    <tr><td></td></tr><tr><td>Currently no logged errors for emails</td></tr>
<# ENDIF #>
</table>

