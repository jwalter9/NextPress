<# IF articles.content #>
<div id="article-head">
    <p id="article-title"><# articles.title #><br />
    <span id="pub-date"><# articles.pubDate #></span> 
    <span id="times-viewed">( viewed <# articles.numViews #> time<# IF articles.numViews != 1 #>s<# ENDIF #> )</span></p>
    <p id="author">
    <# IF articles.avatarUri #><img src="<# articles.avatarUri #>" /><# ENDIF #>
    <# articles.displayName #>
    <# IF url #><br /><a href="<# articles.url #>"><# articles.url #></a><# ENDIF #>
    </p>
</div>
<div id="article-content">
    <# articles.content #>
</div>
<# ELSE #>
<div id="article-content"><h2>Article not found...?</h2></div>
<# ENDIF #>

