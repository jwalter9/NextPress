<!DOCTYPE html>
<html>
<head>
	<title><# domain #> Admin - NextPress</title>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	<link rel="shortcut icon" type="image/x-icon" href="http://<# domain #>/favicon.ico" />
	<link rel="stylesheet" type="text/css" href="/css/admin.css" />
	<script src="//code.jquery.com/jquery-latest.js"></script>
	<script src="//cdn.tinymce.com/4/tinymce.min.js"></script>
	<script src="/js/jquery.nestable.js"></script>
	<script src="/js/admin.js"></script>
</head>
<body>
<div id="mainMenu"><ul id="mainHoriz">
<# IF menu.NUM_ROWS > 0 #>
    <li><div id="linkDrop">
        <div id="mainMenuList"><ul id="dropList">
            <# LOOP menu #><li><a href="<# uri #>"><# label #></a></li>
            <# ENDLOOP #></ul></div>
        </div></li>
<# ENDIF #>
    <li id="page-name"><# mvp_template #></li>
<# LOOP notifications #><li><# INCLUDE notification #></li>
<# ENDLOOP #>
</ul></div>
<div id="pageDiv">
<# IF err #><span class="err"><# err #></span><br /><# ENDIF #>
	<# TEMPLATE #>
</div>

<div id="footer">
    <ul>
        <li><a href="terms.html" target="_blank">Terms of Use</a></li>
        <li>&copy;2017 <a href="http://lowadobe.com" target="_blank">Lowadobe Web Services, LLC</a></li>
        <li><a href="http://nextpress.org" target="_blank">NextPress.org</a></li>
    </ul>
</div>
</body>
</html>

