<# IF err = '' #><script type="text/javascript">
$(document).ready(function()
{
    top.tinymce.activeEditor.insertContent('<img src="<# media.uri #>" alt="media:<# media.id #>" />');
    top.tinymce.activeEditor.windowManager.close();

});
</script><# ENDIF #>
