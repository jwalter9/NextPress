<!DOCTYPE html>
<html>
<head>
	<title><# domain #> Admin - NextPress</title>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	<link rel="shortcut icon" type="image/x-icon" href="http://<# domain #>/favicon.ico" />
	<link rel="stylesheet" type="text/css" href="/css/admin.css" />
	<script src="//code.jquery.com/jquery-latest.js"></script>
	<script src="/js/jquery.nestable.js"></script>
	<script src="/js/admin.js"></script>
</head>
<body>
<div id="mainMenu"><ul id="mainHoriz">
<# IF menu.NUM_ROWS > 0 #>
    <li><div id="linkDrop"><ul id="linkVert"><# LOOP menu #><li><a href="<# uri #>"><# label #></a></li>
    <# ENDLOOP #></ul></div></li>
<# ENDIF #>
    <li id="page-name"><# mvp_template #></li>
<# LOOP notifications #><li><# INCLUDE notification #></li>
<# ENDLOOP #>
</ul></div>
	<# TEMPLATE #>
</body>
</html>

