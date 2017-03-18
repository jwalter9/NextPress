
<div class="form-div">
<h2>Profile</h2>
<form id="profile-form" action="MyProfile" method="post" enctype="multipart/form-data">
    <ul>
        <li><span class="entry-label">Email Address:</span><br />
            &nbsp; &nbsp; &nbsp;<input type="text" name="eml" value="<# users.email #>" /></li>
        <li class="spacer"></li>
        <li><span class="entry-label">Display Name:</span><br />
            &nbsp; &nbsp; &nbsp;<input type="text" name="dname" value="<# users.displayName #>" /></li>
        <li class="spacer"></li>
        <li><span class="entry-label">URL (optional):</span><br />
            &nbsp; &nbsp; &nbsp;<input type="text" name="uurl" value="<# users.url #>" /></li>
        <li class="spacer"></li>
        <li><span class="entry-label">Avatar:</span><# IF users.avatar #><img src="avUri" /><# ENDIF #><br />
            &nbsp; &nbsp; &nbsp;
            <input type="file" name="avFile" /></li>
        <li class="spacer"></li>
        <# IF notAvail = 'yes' #>
        <li><span class="entry-label">Notify Me when new articles are published:</span>
            <input type="checkbox" name="notArt" value="1"<# IF users.notArt > 0 #> checked="checked"<# ENDIF #> /></li>
        <li class="spacer"></li>
        <# ENDIF #>
        <li class="spacer"></li>
        <li><input type="submit" value="Save Changes" /></li>
    </ul>
</form>
</div>

<div class="form-div">
<h2>Change Password</h2>
    <ul>
        <li><span class="entry-label">Current Password:</span><br />
            &nbsp; &nbsp; &nbsp;<input type="password" id="oldPass" value="" /></li>
        <li class="spacer"></li>
        <li><span class="entry-label">New Password:</span><br />
            &nbsp; &nbsp; &nbsp;<input type="password" id="newPass" value="" /></li>
        <li class="spacer"></li>
        <li class="spacer"></li>
        <li><input type="button" value="Update Password" onclick="updatePass();" /></li>
    </ul>
</div>

