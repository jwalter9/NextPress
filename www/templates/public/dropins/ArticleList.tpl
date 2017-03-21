<div id="teaser-list"><ul><# LOOP articles #>
	<li><# IF teasePic != '' #><img src="<# teasePic #>" alt=""/><# ENDIF #>
	    <p><a href="<# IF uri #><# uri #><# ELSE #>/<# ENDIF #>"><# title #></a></p>
	    <p><# pubDate #></p>
	    <p><# teaser #></p></li>
<# ENDLOOP #></ul></div>

