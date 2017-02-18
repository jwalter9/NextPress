<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
	<title><# domain #> Admin - NextPress</title>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	<link rel="stylesheet" type="text/css" href="/css/site.css" />
	<# LOOP plugins #><# IF css != '' #>
		<link rel="stylesheet" type="text/css" href="<# css #>" /><# ENDIF #><# ENDLOOP #>
	<# IF mobile = 'Y' #><link rel="stylesheet" type="text/css" href="/css/mobile.css" /><# ENDIF #>
	<link rel="stylesheet" type="text/css" href="/css/admin.css" />
	<script src="//code.jquery.com/jquery-latest.js"></script>
	<script src="/js/admin.js"></script>
</head>
<body>
	<# TEMPLATE #>
</body>
</html>

