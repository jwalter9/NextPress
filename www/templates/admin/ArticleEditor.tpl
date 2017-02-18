<form id="article-editor" action="/ArticleEditor" method="post">
    <input type="hidden" id="articleId" name="articleId" value="<# articles.id #>"/>
    <p> Title: <input type="text" id="titlein" onkeyup="makeUri(this);" name="titlein" value="<# articles.title #>" size="50"/></p>
    <p> URI: <input type="text" id="uriin" name="uriin" value="<# articles.uri #>" size="40"/></p>
    <p><textarea id="contentin" name="contentin"><# articles.content #></textarea></p>
    <p style="width: 1024px; text-align: center;"> <input type="submit" value="  Save Article  "/></p>
</form>

<# INCLUDE tagDiv #>
<# INCLUDE catDiv #>
<# INCLUDE mediaDiv #>

