
<span class="pagesub"><a href="/ArticleEditor">Write a new Article</a></span>

<table id="artlist">
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
        <td><a href="/ArticlePreview?articleId=<# id #>">view</a><br />
            <a href="/ArticleEditor?articleId=<# id #>">edit</a></td>
    </tr><# SET oldest = id #><# ENDLOOP #>
    <# IF @.oldest > earliest #>
    <tr class="artlist-foot">
        <td colspan="4"><a href="#" onclick="moreArticles(<# @.oldest #>);">More...</a></td>
    </tr><# ENDIF #>
</table>

