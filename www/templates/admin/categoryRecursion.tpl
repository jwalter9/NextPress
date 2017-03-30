<ol class="dd-list" id="parent<# @.parentId #>"><# LOOP categories #><# IF idParent = @.parentId #>
<li class="dd-item" data-id="<# id #>"><div id="<# id #>" class="dd-handle" data-uri="<# uri #>" onmousedown="editCategory(this);"><# displayName #></div>
<# SET parentId = id #><# INCLUDE categoryRecursion #></li><# ENDIF #><# ENDLOOP #></ol><# SET parentId = idParent #>

