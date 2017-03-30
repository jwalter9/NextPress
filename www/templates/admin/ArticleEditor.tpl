<form id="article-editor" action="/ArticleEditor" method="post">
    <input type="hidden" id="articleId" name="articleId" value="<# articles.id #>"/>
    <div id="editor-meta">
        <ul>
            <li class="editor-entry">
                &nbsp;
            </li>
            <li class="editor-entry">
                <input type="submit" value="Save" />
            </li>
        <# IF categories.NUM_ROWS > 0 #>
            <li class="editor-entry">
                Category: <select name="catId"><option>Select a Category</option><# LOOP categories #>
                <option value="<# id #>"<# IF id = articles.idCategory #> selected="selected"<# ENDIF #>>
                    <# indent #><# displayName #></option><# ENDLOOP #>
                </select>
            </li>
        <# ENDIF #>
            <li class="editor-entry">
                Uri: <i>http://your-domain/</i>
                <input type="text" name="uriin" id="uri" value="<# articles.uri #>" onkeyup="makeUri(this);" />
            </li>
            <li class="editor-entry">
                Title: 
                <input type="text" id="titlein" onkeyup="makeUri(this);" name="titlein" value="<# articles.title #>" size="50"/>
            </li>
        </ul>
    </div>
    <div class="spacer"></div>
    <div id="editor">
        <textarea id="articleeditor" name="contentin"><# articles.content #></textarea>
    </div>
</form>
<iframe id="tagdiv" src="/ArticleTags?articleId=<# articles.id #>" />


