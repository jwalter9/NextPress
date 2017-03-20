
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

function publish_page(uri, mobile){
    $.ajax({
        url: "/publishPage",
        data: { pageUri: uri, pageMobile: mobile, invRev: 1 },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ){
            alert(data.PROC_OUT[0].err);
        }else{
            $( "#pubit" ).hide();
            $( "#unpubit" ).show();
        };
    });
}

function unpublish_page(uri, mobile){
    $.ajax({
        url: "/publishPage",
        data: { pageUri: uri, pageMobile: mobile, invRev: 0 },
        dataType: "json",
        cache: false
    }).done(function( data ) {
        if( data.PROC_OUT[0].err != '' ){
            alert(data.PROC_OUT[0].err);
        }else{
            $( "#unpubit" ).hide();
            $( "#pubit" ).show();
        };
    });
}

$(document).ready(function()
{
    $('#nestable').nestable({ maxDepth: 3 });
});

var newCatIter = 0;

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
		selector: "textarea#pageeditor",
		file_picker_types: 'file image',
		file_picker_callback: function(cb, value, meta) {
		    var input = document.createElement('input');
		    input.setAttribute('type', 'file');
		    input.onchange = function() {
		        var file = this.files[0];
		        var id = 'blobid' + (new Date()).getTime();
		        var blobCache = tinymce.activeEditor.editorUpload.blobCache;
		        var blobInfo = blobCache.create(id, file);
		        blobCache.add(blobInfo);
		        cb(blobInfo.blobUri(), { title: file.name });
		    };
		    input.click();
		},
		images_upload_handler: function (blobInfo, success, failure) {
		    $.ajax({
                url: "/addMedia",
                data: { upload: blobInfo.blob(), fname: blobInfo.filename() },
                dataType: "json",
                cache: false
            }).done(function( data ) {
                if( data.PROC_OUT[0].err != '' ) failure(data.PROC_OUT[0].err);
                else success(data.media[0].uri);
            });
		},
		theme: "modern",
		setup: function (editor) {
		    editor.addButton('browsemedia', {
		            text: 'Browse Media',
		            icon: false,
		            onclick: function () {
		                window.open('/Media','_blank');
		            }
		    });
		},
		setup: function (editor) {
		    editor.addButton('dropins', {
		            text: 'Browse Drop-Ins',
		            icon: false,
		            onclick: function () {
		                window.open('/Dropins','_blank');
		            }
		    });
		},
		plugins: [
	        	"advlist autolink lists link image charmap print preview hr anchor pagebreak",
	        	"searchreplace wordcount visualblocks visualchars code fullscreen",
	        	"insertdatetime media nonbreaking save table contextmenu directionality",
	        	"emoticons template paste textcolor colorpicker textpattern imagetools"
	        ],
	        toolbar: "undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist | link media | browsemedia | dropins",
	        content_css: "/css/admin.css",
	        width: $(document).width,
	        height: 700
        });
    
	
	tinymce.init({
		selector: "textarea#articleeditor",
		file_picker_types: 'file image',
		file_picker_callback: function(cb, value, meta) {
		    var input = document.createElement('input');
		    input.setAttribute('type', 'file');
		    input.onchange = function() {
		        var file = this.files[0];
		        var id = 'blobid' + (new Date()).getTime();
		        var blobCache = tinymce.activeEditor.editorUpload.blobCache;
		        var blobInfo = blobCache.create(id, file);
		        blobCache.add(blobInfo);
		        cb(blobInfo.blobUri(), { title: file.name });
		    };
		    input.click();
		},
		images_upload_handler: function (blobInfo, success, failure) {
		    $.ajax({
                url: "/addMedia",
                data: { upload: blobInfo.blob(), fname: blobInfo.filename() },
                dataType: "json",
                cache: false
            }).done(function( data ) {
                if( data.PROC_OUT[0].err != '' ) failure(data.PROC_OUT[0].err);
                else success(data.media[0].uri);
            });
		},
		theme: "modern",
		setup: function (editor) {
		    editor.addButton('browsemedia', {
		            text: 'Browse Media',
		            icon: false,
		            onclick: function () {
		                window.open('/Media','_blank');
		            }
		    });
		},
		setup: function (editor) {
		    editor.addButton('tags', {
		            text: 'Article Tags',
		            icon: false,
		            onclick: function () {
		                window.open('/ArticleTags','_blank');
		            }
		    });
		},
		plugins: [
	        	"advlist autolink lists link image charmap print preview hr anchor pagebreak",
	        	"searchreplace wordcount visualblocks visualchars code fullscreen",
	        	"insertdatetime media nonbreaking save table contextmenu directionality",
	        	"emoticons template paste textcolor colorpicker textpattern imagetools"
	        ],
	        toolbar: "undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist | link media | browsemedia | tags",
	        content_css: "/css/admin.css",
	        width: $(document).width,
	        height: 700
        });
});

