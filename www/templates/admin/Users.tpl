
<form action="Users" method="post">
<ul>
    <li class="horiz"><span class="horiz-head">Filters</span></li>
    <li class="horiz spacer"></li>
    <li class="horiz"><span class="horiz-label">Role:</span></li>
    <li class="horiz"><select name="roleId"><# LOOP roles #>
            <option value="<# id #>" <# IF PROC_OUT.roleId = id #>selected="selected" <# ENDIF #>/><# label #></option>
        <# ENDLOOP #></select></li>
    <li class="horiz spacer"></li>
    <li class="horiz"><span class="horiz-label">Search:</span></li>
    <li class="horiz"><input type="text" name="srch" value="<# srch #>" /></li>
    <li class="horiz spacer"></li>
    <li class="horiz"><input type="submit" value="Update List" /></li>
</ul>
</form>

<table>
    <tr><th>Avatar</th><th>Display Name</th><th>Email Address</th><th>Url</th><th>Roles</th><th>Prohibited?</th></tr>
    <# LOOP users #><tr>
        <td><# IF avatarUri #><img src="<# avatarUri #>" /><# ENDIF #></td>
        <td><# displayName #></td>
        <td><a href="mailto:<# email #>"><# email #></a></td>
        <td><# url #></td>
        <td><# roleList #><br /><a href="/UserRoles?idUsr=<# id #>" target="_blank">Manage</a></td>
        <td><input type="checkbox" onclick="prohibit(<# id #>,this);" <# IF prohibited = 1 #>checked="checked" <# ENDIF #>/></td>
    </tr><# ENDLOOP #>
</table>

