<div id="teaser-list"><ul><# IF articles.NUM_ROWS > 0 #><# LOOP articles #>
	<li><# IF teasePic != '' #><img src="<# teasePic #>" alt=""/><# ENDIF #>
	    <p><a href="<# IF uri #><# uri #><# ELSE #>/<# ENDIF #>"><# title #></a></p>
	    <p><# pubDate #></p>
	    <p><# teaser #></p></li>
<# ENDLOOP #><# ELSE #><li>No matching articles found.</li><# ENDIF #></ul></div>

