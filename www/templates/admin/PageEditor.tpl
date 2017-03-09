<form action="/PageEditor" method="post">
    <div id="editor-meta">
        <ul>
            <li class="editor-entry">
                &nbsp;
            </li>
        <# IF pages.content #>
            <li id="unpubit" class="editor-entry"<# IF pagePub = 0 #> style="display:none;"<# ENDIF #>>
                <a href="#" onclick="unpublish_page('<# pageUri #>', '<# pageMobile #>');">Un-publish</a></li>
            <li id="pubit" class="editor-entry"<# IF pagePub = 1 #> style="display:none;"<# ENDIF #>>
                <a href="#" onclick="publish_page('<# pageUri #>', '<# pageMobile #>');">Publish</a></li>
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
                Page Uri: <i>http://your-domain/</i><label id="uri-preview" />
                <input type="text" name="pageUri" id="pageUri" value="<# pageUri #>" onkeyup="previewUri();" />
            </li>
        </ul>
    </div>
    <div class="spacer"></div>
    <div id="editor">
        <textarea id="page-content" name="pageContent"><# pageContent #></textarea>
    </div>
</form>
<# INCLUDE dropinDiv #>
<# INCLUDE mediaDiv #>

