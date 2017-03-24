<span class="notice">Click a Category to edit or remove; click and drag to place it.</span>
<div class="dd" id="nestable">
    <# SET parentId = 1 #><# INCLUDE categoryRecursion #>
</div>
<div id="cat-edit" class="form-div">
    <ul class="form-entry">
        <li class="form-entry">Display Name:<br /><input type="text" id="dispName"/></li>
        <li class="spacer"></li>
        <li class="form-entry">Uri:<br /><input type="text" id="uri" onkeyup="makeUri(this);"/></li>
        <li class="spacer"><input type="hidden" id="beingEdited" value="" />
                           <input type="hidden" id="newCatIter" value="0" /></li>
        <li class="form-entry"><input type="button" value="Update Category" onclick="updateCategory();" /></li>
        <li class="spacer"></li>
        <li class="form-entry"><input type="button" value="Remove Category" onclick="removeCategory();" /></li>
        <li class="spacer"></li>
        <li><hr></li>
        <li class="spacer"></li>
        <li class="form-entry"><input type="button" value="Add New Category" onclick="newCategory();" /></li>
        <li class="spacer"></li>
        <li class="form-entry">
            <form action="/UpdateCategories" method="post" onsubmit="return saveCategories();">
                <input type="hidden" id="htmlCategories" name="htmlCategories" />
                <input type="submit" value="Save Changes" />
            </form>
        </li>
        <li class="spacer"></li>
        <li class="form-entry">
            <form action="/Categories" method="get">
                <input type="submit" value="Discard Changes" />
            </form>
        </li>
    </ul>
</div>

