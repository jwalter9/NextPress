
<span class="pagesub"><a href="/PageEditor">Create a new Page</a></span><br />

<table>
    <tr><th>URI</th><th>Template</th><th>Mobile?</th><th>Published?</th><th></th></tr>
    <# LOOP pages #><tr>
        <td><# uri #></td>
        <td><# tpl #></td>
        <td><# IF mobile > 0 #>yes<# ELSE #>no<# ENDIF #></td>
        <td><# IF published > 0 #>yes<# ELSE #>no<# ENDIF #></td>
        <td><a href="/PageEditor?pageUri=<# uri #>&pageMobile=<# mobile #>" target="_blank">edit</a></td>
    </tr><# ENDLOOP #>
</table>


