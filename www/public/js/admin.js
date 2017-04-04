
function setPerm(role,perm,cbox){
    var inv = '0';
    if(cbox.checked) inv = '1';
    $.ajax({
        url: "/setPermission",
        data: { roleId: role, permId: perm, invRev: inv },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ) alert(data.PROC_OUT[0].err);
    });
}

function setUserRole(usr,role,cbox){
    var inv = '0';
    if(cbox.checked) inv = '1';
    $.ajax({
        url: "/setUserRole",
        data: { idUsr: usr, roleId: role, invRev: inv },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ) alert(data.PROC_OUT[0].err);
    });
}

function prohibit(usr,cbox){
    var inv = '0';
    if(cbox.checked) inv = '1';
    $.ajax({
        url: "/prohibitUser",
        data: { idUser: usr, prohib: inv },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ) alert(data.PROC_OUT[0].err);
    });
}

function setConfigText(item,section,id){
    var val = document.getElementById(id).value;
    $.ajax({
        url: "/setConfig",
        data: { cid: item, pid: section, cval: val },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ) alert(data.PROC_OUT[0].err);
    });
}

function setConfigSelect(item,section,id){
    var elem = document.getElementById(id);
    var val = elem.options[elem.selectedIndex].value;
    $.ajax({
        url: "/setConfig",
        data: { cid: item, pid: section, cval: val },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ) alert(data.PROC_OUT[0].err);
    });
}

function updatePass(){
    var op = document.getElementById('oldPass').value;
    var np = document.getElementById('newPass').value;
    $.ajax({
        url: "/updatePass",
        data: { oldPass: op, newPass: np },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ) alert(data.PROC_OUT[0].err);
    });
}

function deleteMedia(id){
    $.ajax({
        url: "/deleteMedia",
        data: { mid: id },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ) alert(data.PROC_OUT[0].err);
    });
}

function makeUri(inp){
    var uri = inp.value.toLowerCase();
    uri = uri.replace(/\ /g, '_');
    uri = uri.replace(/-/g, '_');
    uri = uri.replace(/\W/g, '');
    uri = uri.replace(/_/g, '-');
    document.getElementById('uri').value = uri;
}

function moreArticles(id){
    $.ajax({
        url: "/moreArticles",
        data: { top: id },
        dataType: "html",
        cache: false
    }).done(function( data ) {
        document.getElementById('artlist').innerHTML = data;
    });
}

function addDropTag(cbox, artid, tagid){
    var inv = '0';
    if(cbox.checked) inv = '1';
    $.ajax({
        url: "/addDropTag",
        data: { articleId: artid, tagId: tagid, invRev: inv },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ) alert(data.PROC_OUT[0].err);
    });
}

function publish_article(id){
    $.ajax({
        url: "/publishArticle",
        data: { articleId: id, invRev: 1 },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ){
            alert(data.PROC_OUT[0].err);
        }else{
            document.getElementById('pub'+id).value = 
                data.PROC_OUT[0].notificationsSent + ' notifications sent';
            document.getElementById('pub'+id).disabled = true;
        };
    });
}

function unpublish_article(id){
    $.ajax({
        url: "/publishArticle",
        data: { articleId: id, invRev: 0 },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ){
            alert(data.PROC_OUT[0].err);
        }else{
            document.getElementById('pub'+id).value = 'Article Unpublished';
            document.getElementById('pub'+id).disabled = true;
        };
    });
}

function edit_page(tpl, uri, mob, pub){
    document.getElementById('pageTpl').value = tpl;
    document.getElementById('tplLabel').innerHTML = tpl;
    document.getElementById('uri').value = uri;
    document.getElementById('pageMobile').checked = (mob == 1 ? 'checked' : '');
    document.getElementById('pagePublished').checked = (pub == 1 ? 'checked' : '');
    document.getElementById('tpl-edit').style = 'display: block;';
}

$(document).ready(function()
{
    $('#nestable').nestable({ maxDepth: 3 });
});

function newCategory(){
    var newCatIter = document.getElementById('newCatIter').value;
    newCatIter++;
    document.getElementById('dispName').value = '';
    document.getElementById('uri').value = '';
    var $newLi = $('<li class="dd-item" data-id=""><div id="new'+newCatIter+
        '" data-uri="" class="dd-handle" onmousedown="editCategory(this);"></div></li>');
    $('#parent1').append($newLi);
    document.getElementById('beingEdited').value = "new"+newCatIter;
    document.getElementById('newCatIter').value = newCatIter;
}

function editCategory(dv){
    document.getElementById('beingEdited').value = dv.getAttribute('id');
    document.getElementById('dispName').value = dv.innerHTML;
    document.getElementById('uri').value = dv.getAttribute("data-uri");
}

function updateCategory(){
    var editId = document.getElementById('beingEdited').value;
    var editCat = document.getElementById(editId);
    editCat.innerHTML = document.getElementById('dispName').value;
    editCat.setAttribute("data-uri", document.getElementById('uri').value);
}

function removeCategory(){
    var editId = document.getElementById('beingEdited').value;
    var editCat = document.getElementById(editId);
    var parentCat = editCat.parentNode;
    parentCat.remove(editCat);
    document.getElementById('dispName').value = "";
    document.getElementById('uri').value = "";
    document.getElementById('beingEdited').value = "";
}

function saveCategories(){
    document.getElementById('htmlCategories').value = document.getElementById('nestable').innerHTML;
    return true;
}

$(document).ready(function() {
	tinymce.init({
		selector: "textarea#articleeditor",
		setup: function (editor) {
		    editor.addButton('addmedia', {
		            text: 'Insert Image',
		            icon: false,
		            onclick: function () {
		                editor.windowManager.open({
		                        title: 'Insert Image',
		                        url: '/addMedia',
		                        width: 400,
		                        height: 100
		                });
		            }
		    });
		},
		theme: "modern",
		plugins: [
	        	"advlist autolink lists link image charmap print preview hr anchor pagebreak",
	        	"searchreplace wordcount visualblocks visualchars code fullscreen",
	        	"insertdatetime media nonbreaking save table contextmenu directionality",
	        	"emoticons template paste textcolor colorpicker textpattern imagetools"
	        ],
	        toolbar: "undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist | link media | addmedia",
	        content_css: "/css/admin.css",
	        height: 450
        });
});

