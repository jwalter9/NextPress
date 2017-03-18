
<# IF messg #><h2><# messg #></h2><# ENDIF #>

<div class="form-div">
<h2>Import WordPress XML</h2>
<form id="wpi-form" action="WPImport" method="post" enctype="multipart/form-data">
    <ul>
        <li><span class="entry-label">XML File to Upload:</span><br />
            &nbsp; &nbsp; &nbsp;<input type="file" name="xmlFile" /></li>
        <li class="spacer"></li>
        <li class="spacer"></li>
        <li><input type="submit" value="Import" /></li>
    </ul>
</form>
</div>


