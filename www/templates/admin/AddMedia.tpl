<# IF newId > 0 #>
<span class="info">The following <# IF media.isImage > 0 #>image<# ELSE #>file<# ENDIF #> has been added.<br />
                   To include in a page or article, just drag/drop or copy/paste where you want it.</span><br />
    <# IF media.isImage > 0 #><img src="<# uri #>" /><# ELSE #><a href="<# uri #>"><# uri #></a><# ENDIF #>
<# ELSE #>
<span class="pagehead">Upload Media</span>
<form action="/AddMedia" method="post" enctype="multipart/form-data" onsubmit="return addMedia();">
<input type="hidden" id="fname" name="fname" value="" />
<ul>
    <li><span class="entry-label">File:</span><input type="file" name="upload" id="upload" /></li>
    <li><input type="submit" value="Upload" /></li>
</ul>
</form>
<# ENDIF #>

