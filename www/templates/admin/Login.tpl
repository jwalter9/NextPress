
<form id="login-form" action="Login" method="post">
    <ul>
        <li><span class="entry-label">Email Address:</span><input type="text" name="eaddr" value="" /></li>
        <li><span class="entry-label">Password:</span><input type="password" name="passwd" value="" /></li>
        <li><input type="submit" value="Login" /></li>
    </ul>
</form>
<# IF canRegister = 'yes' #>
<span class="pagesub">Register</span>
<form id="register-form" action="Register" method="post">
    <ul>
        <li><span class="entry-label">Email Address:</span><input type="text" name="eaddr" value="" /></li>
        <li><input type="submit" value="Register" /></li>
    </ul>
</form>
<# ENDIF #>
<span class="pagesub">Forgot Password</span>
<form id="forgot-form" action="ForgotPassword" method="post">
    <ul>
        <li><span class="entry-label">Email Address:</span><input type="text" name="eaddr" value="" /></li>
        <li><input type="submit" value="Reset Password" /></li>
    </ul>
</form>

