<div id="media-div">
    <ul>
        <li id="pop-add-media" /><img src="/media/plugins/addMedia.png" /></li>
        <# LOOP media #><li class="media-list">
        <# IF isImage #><img src="<# uri #>" /><# ELSE #><a href="<# uri #>" target="_blank"><# uri #></a><# ENDIF #>
        </li><# ENDLOOP #>
    </ul>
</div>

