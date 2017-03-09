
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

function addMedia(){
    var filinp = document.getElementById('upload').value;
    if(filinp == ''){
        alert('Please select a file to upload.');
        return false;
    };
    filinp = filinp.substring(filinp.lastIndexOf("/") + 1);
    filinp = filinp.substring(filinp.lastIndexOf("\\") + 1);
    document.getElementById('fname').value = filinp;
    return true;
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
    document.getElementById('uriin').value = uri;
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

function unpublish_page(id){
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
    $('#nestable').nestable();
});

var catLiBeingEdited;

function newCategory(){
    $("#dispName").value = '';
    $("#uriin").value = '';
    var $newLi = $('<li class="dd-item" data-id="" data-uri=""><div class="dd-handle"></div></li>');
    $("#parent0").append($newLi);
    catLiBeingEdited = $newLi;
}

function editCategory(li){
    catLiBeingEdited = li;
    $("#dispName").value = li.find("div").innerHTML;
    $("#uriin").value = li.attr("data-uri");
}

function updateCategory(){
    catLiBeingEdited.find("div").innerHTML = $("#dispName").value;
    catLiBeingEdited.attr("data-uri", $("#uriin").value);
}

function saveCategories(){
    $("#htmlCategories").value = $("#nestable").innerHTML;
    return true;
}

$(document).ready(function() {
	
	tinymce.init({
		selector: "textarea",
		theme: "modern",
		plugins: [
	        	"advlist autolink lists link image charmap print preview hr anchor pagebreak",
	        	"searchreplace wordcount visualblocks visualchars code fullscreen",
	        	"insertdatetime media nonbreaking save table contextmenu directionality",
	        	"emoticons template paste textcolor colorpicker textpattern imagetools"
	        ],
	        toolbar: "undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist | link media",
	        content_css: "/css/admin.css",
	        width: $(document).width,
	        height: $(document).height
        });
        });

