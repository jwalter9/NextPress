
<span class="pagehead">Roles for <# users.displayName #></span>

<ul>
<# LOOP roles #><# SET roleid = id #>
    <li><input type="checkbox" onclick="setUserRole(<# users.id #>,<# id #>,this);"<#
            LOOP user_roles #><# IF idRole = @.roleid #> checked="checked"<#
            ENDIF #><# ENDLOOP #> /><span class="entry-label"><# label #></span></li>
<# ENDLOOP #>
</ul>

