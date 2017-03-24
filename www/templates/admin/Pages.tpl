
<table id="page-table">
    <tr><th>Template</th><th>URI</th><th>Mobile?</th><th>Published?</th><th></th></tr>
    <# LOOP pages #><tr>
        <td><# tpl #>.tpl</td>
        <td><# uri #></td>
        <td><# IF mobile > 0 #>Yes<# ELSE #>No<# ENDIF #></td>
        <td><# IF published < 0 #>File Missing<# ELSIF published = 0 #>No<# ELSE #>Yes<# ENDIF #></td>
        <td><input type="button" value="Edit" onclick="edit_page('<# tpl #>','<# uri #>',<# mobile #>,<# published #>);" /></td>
    </tr><# ENDLOOP #>
</table>

<div id="tpl-edit" class="form-div" style="display: none;">
    <form action="/UpdatePage" method="post">
        <input type="hidden" id="pageTpl" name="pageTpl" value="" />
    <ul class="form-entry">
        <li class="form-entry" id="tplLabel"></li>
        <li class="spacer"></li>
        <li class="form-entry">URI:<br /><input type="text" id="uri" name="pageUri" onkeyup="makeUri(this);"/></li>
        <li class="spacer"></li>
        <li class="form-entry">Mobile: <input type="checkbox" id="pageMobile" name="pageMobile" value="1" /></li>
        <li class="spacer"></li>
        <li class="form-entry">Published: <input type="checkbox" id="pagePublished" name="pagePublished" value="1" /></li>
        <li class="spacer"></li>
        <li class="form-entry"><input type="submit" value="Save" />
        <li class="spacer"></li>
    </ul>
    </form>
</div>

