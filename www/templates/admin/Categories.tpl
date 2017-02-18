<div class="dd" id="nestable">
    <# htmlCategories #>
</div>
<div id="cat-edit">
    <ul class="form-entry">
        <li class="form-entry">Display Name:<br /><input type="text" id="dispName" onkeyup="makeUri(this);" /></li>
        <li class="form-entry">Uri:<br /><input type="text" id="uriin" /></li>
        <li class="form-entry"><input type="button" value="Update Category" onclick="updateCategory();" /></li>
        <li class="form-entry"><input type="button" value="Add New Category" onclick="newCategory();" /></li>
        <li class="form-spacer"></li>
        <li class="form-entry">
            <form action="/UpdateCategories" method="post" onsubmit="return saveCategories();">
                <input type="hidden" id="htmlCategories" name="htmlCategories" />
                <input type="submit" value="Save Changes" />
            </form>
        </li>
        <li class="form-spacer"></li>
        <li class="form-entry">
            <form action="/Categories" method="get">
                <input type="submit" value="Discard Changes" />
            </form>
        </li>
    </ul>
</div>

