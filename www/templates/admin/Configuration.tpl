
<span class="pagehead">Configuration</span>

<div class="empty"><ul class="empty">
<# LOOP config #><# IF section != @.sect #>
    </ul></div><div class="config-section"><span class="config-section"><# section #></span>
    <ul><# ENDIF #>
        <li><span class="config-description"><# description #></span>
            <# IF idSelect #><select id="<# section #>_<# id #>"><# SET selected = val, selectid = idSelect #>
                <# LOOP config_selection #><# IF idGroup = @.selectid 
                    #><option value="<# val #>"<# IF val = @.selected #> selected="selected"<# ENDIF #>><# val #></option><# ENDIF #>
                <# ENDLOOP #></select><input type="button" onclick="setConfigSelect('<# id #>','<# section #>','<# section #>_<# id #>');" value="Save" />
            <# ELSE #><input type="text" id="<# section #>_<# id #>" value="<# val #>" />
                <input type="button" onclick="setConfigText('<# id #>','<# section #>','<# section #>_<# id #>');" value="Save" />
            <# ENDIF #>
        </li>
<# SET sect = section #><# ENDLOOP #>
</ul></div>

