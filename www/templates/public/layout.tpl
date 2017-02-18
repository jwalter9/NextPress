<!DOCTYPE html>
<html>
<head>
	<title><# ptitle #></title>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	<meta http-equiv="keywords" content="<# keywords #>" />
	<link rel="shortcut icon" type="image/x-icon" href="http://<# domain #>/favicon.ico" />
	<link rel="stylesheet" type="text/css" href="/css/site.css" />
	<# LOOP dropins #><# IF css != '' #>
		<link rel="stylesheet" type="text/css" href="/css/<# css #>" /><# ENDIF #><# ENDLOOP #>
	<# IF mobile = 'Y' #><link rel="stylesheet" type="text/css" href="/css/mobile.css" /><# ENDIF #>
	<script src="//code.jquery.com/jquery-latest.js"></script>
	<script src="/js/site.js"></script>
	<# LOOP dropins #><# IF js != '' #>
		<script src="/js/<# js #>" /><# ENDIF #><# ENDLOOP #>
</head>
<body>
    <# TEMPLATE #>
</body>
</html>

