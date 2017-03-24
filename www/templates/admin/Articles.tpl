
<span class="pagesub"><a href="/ArticleEditor">Write a new Article</a></span>

<table id="artlist">
<# IF articles.NUM_ROWS > 0 #>
    <tr class="artlist-head"><th>Author</th><th>Title</th><th>Published</th><th></th></tr>
    <# LOOP articles #><tr>
        <td><# IF avatarUri #><img src="/avatarUri" /><br /><# ENDIF #>
            <span class="artlist-author"><# displayName #></td>
        <td><span class="artlist-title"><# title #></span><br />
            <span class="artlist-teaser"><# teaser #></span></td>
        <td><span class="artlist-pubdate"><# pubDate #></span><br />
            <# IF pubDate = 'Unpublished' #>
            <input id="pub<# id #>" type="button" value="Publish" onclick="publish_article(<# id #>);" />
            <# ELSE #>
            <input id="pub<# id #>" type="button" value="Unpublish" onclick="unpublish_article(<# id #>);" />
            <# ENDIF #></td>
        <td><a href="/ArticleEditor?articleId=<# id #>" target="_blank">edit</a></td>
    </tr><# SET oldest = id #><# ENDLOOP #>
    <# IF @.oldest > earliest #>
    <tr class="artlist-foot">
        <td colspan="4"><a href="#" onclick="moreArticles(<# @.oldest #>);">More...</a></td>
    </tr><# ENDIF #>
<# ELSE #>
    <tr><td></td></tr><tr><td>There are no articles yet.</td></tr>
<# ENDIF #>
</table>

