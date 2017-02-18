<# IF pages.content #>
<div id="pub-div">
    <ul>
        <li id="unpubit" class="button right"<# IF pagePub = 0 #> style="display:none;"<# ENDIF #>>
            <a href="#" onclick="unpublish_page('<# pageUri #>', '<# pageMobile #>');">Un-publish</a></li>
        <li id="pubit" class="button right"<# IF pagePub = 1 #> style="display:none;"<# ENDIF #>>
            <a href="#" onclick="publish_page('<# pageUri #>', '<# pageMobile #>');">Publish</a></li>
    </ul>
</div>  
<# ENDIF #>
<form action="/PageEditor" method="post">
    <div id="editor-meta">
        <ul>
            <li class="editor-entry">
                <input type="text" name="pageUri" id="pageUri" value="<# pageUri #>" onkeyup="previewUri();" />
                <br />Page Uri: <i>http://your-domain/</i><label id="uri-preview" />
            </li>
            <li class="editor-entry">
                <input type="text" name="pageTpl" id="pageTpl" value="<# pageTpl #>" onkeyup="previewTpl();" />
                <br />Page Template: <label id="tpl-preview" />
            </li>
            <li class="editor-entry">
                <input type="checkbox" name="pageMobile" id="pageMobile" value="1"<# IF pageMobile = 1 #> checked="checked"<# ENDIF #> />
                &nbsp; For Mobile Browsers
            </li>
            <li class="editor-entry">
                <input type="submit" value="Save" />
            </li>
        </ul>
    </div>
    
    <div id="editor">
        <textarea id="page-content" name="pageContent"><# pageContent #></textarea>
    </div>
</form>
<# INCLUDE dropinDiv #>
<# INCLUDE mediaDiv #>

