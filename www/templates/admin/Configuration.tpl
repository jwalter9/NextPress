
<div class="empty"><ul class="empty"><# SET sect = '' #>
<# LOOP config #><# IF section != @.sect #>
    </ul></div><div class="config-section"><span class="config-section"><# section #></span>
    <ul><# ENDIF #>
        <li><span class="config-description"><# description #></span><br />&nbsp;&nbsp;&nbsp;
            <# IF idSelect #><select id="<# section #>_<# id #>"><# SET selected = val, selectid = idSelect #>
                <# LOOP config_selection #><# IF idGroup = @.selectid 
                    #><option value="<# val #>"<# IF val = @.selected #> selected="selected"<# ENDIF #>><# val #></option><# ENDIF #>
                <# ENDLOOP #></select>&nbsp;
                <input type="button" onclick="setConfigSelect('<# id #>','<# section #>','<# section #>_<# id #>');" value="Save" />
            <# ELSE #><input type="text" size="80" id="<# section #>_<# id #>" value="<# escVal #>" />&nbsp;
                <input type="button" onclick="setConfigText('<# id #>','<# section #>','<# section #>_<# id #>');" value="Save" />
            <# ENDIF #>
        </li>
        <li class="spacer"></li>
<# SET sect = section #><# ENDLOOP #>
</ul></div>

