
<span class="pagehead">My Profile</span>

<form id="profile-form" action="MyProfile" method="post" enctype="multipart/form-data">
    <ul>
        <li><span class="entry-label">Email Address:</span><input type="text" name="eml" value="<# users.email #>" /></li>
        <li><span class="entry-label">Display Name:</span><input type="text" name="dname" value="<# users.displayName #>" /></li>
        <li><span class="entry-label">URL (optional):</span><input type="text" name="uurl" value="<# users.url #>" /></li>
        <li><span class="entry-label">Avatar:</span><# IF users.avatar #><img src="avUri" /><# ENDIF #>
            <input type="file" name="avFile" /></li>
        <# IF notAvail = 'yes' #>
        <li><span class="entry-label">Notify Me when new articles are published:</span>
            <input type="checkbox" name="notArt" value="1"<# IF users.notArt > 0 #> checked="checked"<# ENDIF #> /></li>
        <# ENDIF #>
        <li><input type="submit" value="Save Changes" /></li>
    </ul>
</form>

<span class="pagesub">Change Password</span>
    <ul>
        <li><span class="entry-label">Current Password:</span><input type="password" id="oldPass" value="" /></li>
        <li><span class="entry-label">New Password:</span><input type="password" id="newPass" value="" /></li>
        <li><input type="button" value="Update Password" onclick="updatePass();" /></li>
    </ul>

