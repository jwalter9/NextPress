<# CALL Archives() #><# IF archives.NUM_ROWS > 0 #><# SET curYear = '', curMonth = '' #>
<div id="archive-div">
    <span>Archives</span>
    <ul><# LOOP archives #>
    <# IF yr != @.curYear #><li class="arch-year"><# yr #></li><# SET curYear = yr, curMonth = '' #><# ENDIF #>
    <# IF mnth != @.curMonth #><li class="arch-month"><# mnth #></li><# SET curMonth = mnth #><# ENDIF #>
    <li class="arch-article"><a href="/<# uri #>"><# title #></a></li>
    <# ENDLOOP #></ul>
</div>
<# ENDIF #>

