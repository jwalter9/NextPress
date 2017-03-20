<form action="/PageEditor" method="post">
    <div id="editor-meta">
        <ul>
            <li class="editor-entry">
                &nbsp;
            </li>
        <# IF pageContent #>
            <li id="unpubit" class="editor-entry"<# IF pagePub = 0 #> style="display:none;"<# ENDIF #>>
                <input type="button" onclick="unpublish_page('<# pageUri #>', '<# pageMobile #>');" value="Un-publish"/></li>
            <li id="pubit" class="editor-entry"<# IF pagePub = 1 #> style="display:none;"<# ENDIF #>>
                <input type="button" onclick="publish_page('<# pageUri #>', '<# pageMobile #>');" value="Publish"/></li>
        <# ENDIF #>
            <li class="editor-entry">
                <input type="submit" value="Save" />
            </li>
            <li class="editor-entry">
                For Mobile Browsers:
                <input type="checkbox" name="pageMobile" id="pageMobile" value="1"<# IF pageMobile = 1 #> checked="checked"<# ENDIF #> />
            </li>
            <li class="editor-entry">
                Page Template: <label id="tpl-preview" />
                <input type="text" name="pageTpl" id="pageTpl" value="<# pageTpl #>" onkeyup="previewTpl();" />
            </li>
            <li class="editor-entry">
                Page Uri: <i>http://your-domain/</i>
                <input type="text" name="pageUri" id="uri" value="<# pageUri #>" onkeyup="makeUri(this);" />
            </li>
        </ul>
    </div>
    <div class="spacer"></div>
    <div id="page-editor">
        <textarea id="pageeditor" name="pageContent"><# pageContent #></textarea>
    </div>
</form>

