<# CALL RelatedArticles( articles.id ) #><# IF related.NUM_ROWS > 0 #>
<div id="related-list"><h3>Related articles...</h3>
    <ul><# LOOP related #>
	<li><# IF teasePic != '' #><img src="<# teasePic #>" alt=""/><# ENDIF #>
	    <p><a href="<# IF uri #><# uri #><# ELSE #>/<# ENDIF #>"><# title #></a></p>
	    <p><# pubDate #></p>
	    <p><# teaser #></p></li>
<# ENDLOOP #></ul></div>
<# ENDIF #>
