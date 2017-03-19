
<span class="notice">Drop-ins can be copied and pasted into the PageEditor</span>
<br />
<ul>
    <# IF dropins.NUM_ROWS < 1 #><li>There are no dropins enabled.</li><# ELSE #>
    <# LOOP dropins #>
    <li class="tiles"><img src="/media/dropins/<# img #>" /><br /><# id #></a></li>
    <# ENDLOOP #><# ENDIF #>
</ul>

