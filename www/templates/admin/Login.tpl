
<div class="form-div">
<h2>Login</h2>
<form id="login-form" action="Login" method="post">
    <ul>
        <li><span class="entry-label">Email Address:</span><br />
            &nbsp; &nbsp; &nbsp;<input type="text" name="eaddr" value="" /></li>
        <li class="spacer"></li>
        <li><span class="entry-label">Password:</span><br />
            &nbsp; &nbsp; &nbsp;<input type="password" name="passwd" value="" /></li>
        <li class="spacer"></li>
        <li class="spacer"></li>
        <li><input type="submit" value="Login" /></li>
    </ul>
</form>
</div>

<div class="form-div">
<h2>Forgot Password</h2>
<form id="forgot-form" action="ForgotPassword" method="post">
    <ul>
        <li><span class="entry-label">Email Address:</span><br />
            &nbsp; &nbsp; &nbsp;<input type="text" name="eaddr" value="" /></li>
        <li class="spacer"></li>
        <li class="spacer"></li>
        <li><input type="submit" value="Reset Password" /></li>
    </ul>
</form>
</div>

<# IF canRegister = 'yes' #>
<div class="form-div">
<h2>Register</h2>
<form id="register-form" action="Register" method="post">
    <ul>
        <li><span class="entry-label">Email Address:</span><br />
            &nbsp; &nbsp; &nbsp;<input type="text" name="eaddr" value="" /></li>
        <li class="spacer"></li>
        <li class="spacer"></li>
        <li><input type="submit" value="Register" /></li>
    </ul>
</form>
</div>
<# ENDIF #>

