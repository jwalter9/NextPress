
<span class="notice">Please select all that apply to <# IF artTitle #>&quot;<# artTitle #>&quot;<# ELSE #>the Untitled article with ID <# articleId #><# ENDIF #>.</span>
<br />
<table>
    <# IF tags.NUM_ROWS < 1 #><tr><td></td></tr><tr><td>There are no tags yet.</td></tr><# ELSE #>
    <# LOOP tags #><tr>
        <td><# displayName #><br />(<# uri #>)</td>
        <td><input type="checkbox" value="1" onclick="addDropTag(this, <# PROC_OUT.articleId #>, <# id #>);" <# IF idArticle #>checked="checked" <# ENDIF #>/></td>
    </tr><# ENDLOOP #><# ENDIF #>
</table>

<div id="new-tag" class="form-div">
    <form action="NewTag" method="post">
    <input type="hidden" name="articleId" value="<# articleId #>" />
    <ul class="form-entry">
        <li class="form-entry">Display Name:<br /><input type="text" name="tagName" onkeyup="makeUri(this);"/></li>
        <li class="spacer"></li>
        <li class="form-entry">Uri:<br /><input type="text" id="uri" name="tagUri" onkeyup="makeUri(this);"/></li>
        <li class="spacer"></li>
        <li class="form-entry"><input type="submit" value="Add New Tag" /></li>
    </ul>
    </form>
</div>

