// server
function debug(obj){
//        console.log(obj);
}
// server
if(config == "sinatra"){
    var server = {
        init : function(){
        },
        update_tag:function(id,tagstring){
            this._server_get('image/updatetag/'+id,tagstring,page.emitexif);
        },
        search : function(qstring,kind,p) {
            if(!p){p = 1;}
            this._server_get('search'+ kind , qstring+"&page="+p+"&per=50",page.emitdir);
        },
        dirs : function(){
            this._server_get('dirs',"",page.emitdirs);
        },
        dir : function(id){
            this._server_get('dir/'+ id ,"",page.emitdir);
        },
        exif : function(id){
            this._server_get('image/data/'+ id ,"",page.emitexif);
        },
        _server_get : function(uri,pdata,callback){
            $.ajax({  
                       type: "GET",
                       url: this._prefix + "/" + uri ,
                       data: "qs="+pdata,
                       success: function(msg){
                           debug(msg);
                           callback(msg);
                       },
                       error:function(msg){
                           $("#grayout").fadeIn(0);
                       }
                       
                   });    
        },
        _prefix : "/photodb/api"
    };
}else{
    var server = {
        update_tag:function(id,tagstring){
            this._server_get('image/updatetag/'+id,tagstring,page.emitexif);
        },
        search : function(qstring,retry) {
            page.flgdo = true;
            
            retry = retry ? 0 :1;
            page._paincount = 0;

            page.target_pain_ul = $("#pain").html('<ul></ul>').find('ul');

            if(server._connected){//TODO temporary
                server._ws.send( "get:search:" + encodeURIComponent(qstring) );
            }else{
                //retry
                setTimeout(function(){
                               if(retry > 2){
                                   $("grayout").fadeOut(0);
                                   debug("諦める");
                               }else{
                                   server.search(qstring,retry + 1);
                               }
                           },100);
            }
        },
        dirs : function(retry){
            retry = retry ? 0 :1;
            if(server._connected){//TODO temporary
                server._ws.send( "get:dirs" );
            }else{
                //retry
                setTimeout(function(){
                               if(retry > 2){
                                   $("grayout").fadeOut(0);
                                   debug("諦める");
                               }else{
                                   server.dirs(retry + 1);
                               }
                           },100);
            }
        },
        dir : function(id,retry){
            page.flgdo = true;
            page._paincount = 0;
            //            $("#pain").html('<ul></ul>');
            //            var pain = document.getElementById("pain");
            //            pain.innerHTML = "<ul></ul>";
            page.target_pain_ul = $("#pain").html('<ul></ul>').find('ul');

            retry = retry ? 0 :1;
            if(server._connected){//TODO temporary
                server._ws.send( "get:dir:" + id );
            }else{
                //retry
                setTimeout(function(){
                               if(retry > 2){
                                   $("grayout").fadeOut(0);
                                   debug("諦める");
                               }else{
                                   server.dir(id,retry + 1);
                               }
                           },100);
            }
        },
        exif : function(id){
            this._server_get('image/data/'+ id ,"",page.emitexif);
        },
        _ws :null ,
        init : function(){
            debug("server:init");
            var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
            server._ws = new Socket(server._wsuri);
            server._ws.onmessage = function(evt) {
                if(evt.data.length > 20){
                    var json = eval(evt.data);
                    var callback = json[0]['callback'];json.shift();
                    var data = json;
                    debug(callback);
                    debug(data.length);
                    eval("server." + callback + '(json)' );
                }
            };
            server._ws.onclose = function() { debug("socket closed"); };
            server._ws.onopen = function() {
                server._connected = true;
                debug("Connected.");
                reload_dirs();
            };
        },
        _connected : false,
        callback_api_dirs   : function(json){ 
            debug("callbacked");
            page.emitdirs(json);
        },
        callback_api_dir_e    : function(json){ page.emitdir_e(json);},
        callback_api_search_e : function(json){ page.emitdir_e(json);},
        _server_get : function(uri,pdata,callback){
            $.ajax({  
                       type: "GET",
                       url: this._prefix + "/" + uri ,
                       data: "qs="+pdata,
                       success: function(msg){
                           callback(msg);
                       },
                       error:function(msg){
                           $("#grayout").fadeIn(0);
                       }
                       
                   });    
        },
        _wsuri : "ws://" + location.host + ":8090/",

        _prefix : "/photodb/api",
        _prefix : "api"
    };
    
}

var page = {
    /* manage selected */
    _selected_dirli_id : "",
    _selected_painli_id : "",
    chg_dirli_select : function(id){
        if(this._selected_dirli_id !== ""){
            $('#dirli-' + this._selected_dirli_id ).toggleClass('selected');
        }
        $('#dirli-' + id ).toggleClass('selected');
        this._selected_dirli_id = id;
    },
    chg_painli_select : function(id){
        if(this._selected_painli_id !== ""){
            $('#painli-' + this._selected_painli_id ).toggleClass('selected');
        }
        $('#painli-' + id ).toggleClass('selected');
        this._selected_painli_id = id;

    },
    /* make page */
    emitdirs : function(json){
        //        json = eval(json);
        // set window title and echo area
        if(page._selected_dirli_id === ""){
            $("#echoarea").html('');
        }

        // make page
        $("#side").html('');
        var elems = [];
        for(var i=0;i<json.length;i++){
            if( json[i]['name'] != 'Original' 
                && json[i]['name'] != 'Thumbnail' 
              ){
                  var elem = "<li id='dirli-" + json[i]['_id'] ;
                  elem+= "' onclick='reload_dir(\""+ json[i]['_id'] +"\",this);return false;'>";
                  //            for(x in json[i]){
                  //                elem += x + ":" + json[i][x] + "\n" ;
                  //            }
                  elem += json[i]['name'];
                  elem += "</li>";
                  elem = $(elem);
                  page._set_mover_css2elem(elem,'highlight');
                  elems.push(elem);
              }
        }
        var html = $("<ul></ul>");
        for(var i=0;i<elems.length;i++){
            html.append(elems[i]); 
        }
        $("#side").append(html);

        // ui
        if(page._selected_dirli_id !== ""){
            $('#dirli-' + page._selected_dirli_id ).toggleClass('selected');
        }
        $('#grayout').toggle();
    },
    _paincount : 0,
    emitdir_e : function (json){
        debug("emitdir_e");
        debug(json);
        if($('#query').val() !=''){
            var title = "::search::" + $('#query').val().split(' ').join('&').slice(0,11);
            $('title').html("photodb::search::" + $('#query').val().split(' ').join('&'));
        }else{
            var title = "::dir::" + json[0].path.replace(/^.*\/(.*)\/.*$/,"$1").slice(0,11) + "(" + page._paincount +1 + ")" ;
            $('title').html("photodb::dir::" + json[0].path.replace(/^.*\/(.*)\/.*$/,"$1") + "(" + page._paincount +1  + ")") ;
        }
        $("#echoarea").html(title);
        var elem = "<li id='painli-" + json[0]._id ;
        elem   += "' onclick='display_thumb_m(";
        elem += '"' + json[0]._id+ '","' + json[0].path + '"' ;
        elem += ");return false;'>";
        var img = "<img src='#{src}' alt='#{alt}'>";
        img = img.replace('#{alt}',json[0].name);
        if(json[0].thumb_s){
            img = img.replace('#{src}', "data:image/jpeg;base64," + json[0].thumb_s.data.str);
        }

        elem += img;
        elem += "</li>";
        elem = $(elem);
        page._set_mover_css2elem(elem,'highlight');
        //        $("#pain").find('ul').append(elem);
        setTimeout(function(){ page.target_pain_ul.append(elem);},10);
        // ui
        if(this.flgdo == true){
            $('#grayout').fadeOut(100);
            this.flgdo = false;
        }
    },
    target_pain_ul :null,
    flagdo : true,
    nowdirid:null,
    emitdir : function(json){
        var status = json[0];
        json = json[1];
        // set window title and echo area
try{
    
        if($('#query').val() !=''){
            var title = "::search::" + $('#query').val().split(' ').join('&').slice(0,11);
            if(!AppUtil.isMsIE)
                $('title').html("photodb::search::" + $('#query').val().split(' ').join('&'));
        }else{
            var title = "::dir::" + json[0]['path'].replace(/^.*\/(.*)\/.*$/,"$1").slice(0,11) + "(" + json.length + ")" ;
            if(!AppUtil.isMsIE)
                $('title').html("photodb::dir::" + json[0]['path'].replace(/^.*\/(.*)\/.*$/,"$1") + "(" + json.length + ")") ;
        }
        $("#echoarea").html(title);
} catch (x) {

}
        // make page
        $("#pain").html("");

        var pagina = "<div id='pagination' style='text-align:center'>";
        if(status.prev == "yes")
            pagina += "<span onclick='run(\"#{page}\");'>".replace(/\#\{page\}/g,status.page - 1) + "Prev</span>";
        if(status.prev == "yes" && status.next == "yes")
            pagina += " | ";
        if(status.next == "yes")
            pagina += "<span onclick='run(\"#{page}\")'>".replace(/\#\{page\}/g,status.page + 1) + "Next</span>";;
        pagina += "</div>";
        $("#pain").append(pagina);

        $("#pain").append("<ul>");

        var ul = $("#pain ul");
        var _stop = $("#dirli-" + page.nowdirid).get(0) ? 
            $("#dirli-" + page.nowdirid).get(0).offsetTop - 50 : 0 ;
        if($('#query').val() != '')
            _stop = 0;

        ul.html('');
        ul.css({"margin-top":_stop});
        var elems = [];
        for(var i=0;i<json.length;i++){
            // build html string
            (function(json,i){
            window.setTimeout(function(){
                           var elem = "<li id='painli-" + json[i]['_id'] ;
                           elem   += "' onclick='display_thumb_m(";
                           elem += '"' + json[i]['_id']+ '","' + json[i]['path'] + '"' ;
                           elem += ");return false;'>";
                           var img = "<img src='#{src}' alt='#{alt}'>";
                           img = img.replace('#{alt}',json[i]['name']);
                           if(json[i].thumb_s){
                               img = img.replace('#{src}', "data:image/jpeg;base64," + json[i].thumb_s.str);
                           }
                           elem += img;
                           elem += "</li>";
                           elem = $(elem);
                           page._set_mover_css2elem(elem,'highlight');
                           ul.append(elem);
//                           elems.push(elem);
                       },100*i);
            })(json,i);
        }
//        var html = $("<ul>");
//        for(var i=0;i<elems.length;i++){
//            html.append(elems[i]); 
//        }
//        debug(status);
        $("#pain").append(pagina);

        // ui
        $('#grayout').toggle();
    },
    emitexif : function(json){
        //        json = eval(json);
        
        // make page
        var elem = "<div class='photodata'>"; //todo
        elem  += "<h4>data</h4>";
        elem += "<pre>";
        for(var i=0;i<json.length;i++){
            for(x in json[i]){
                if(x != 'exif' &&
                   /*                   x != 'search' && */
                   x != '_id' &&
                   x != 'path' &&
                   x != 'dirmodel_ids' &&
                   x != 'search' &&
                   x != 'search2' &&
                   x != 'thumb_m' &&
                   x != 'thumb_m64' &&
                   x != 'thumb_s' &&
                   x != 'created_at'
                  ){
                      elem += x + ":" + json[i][x] + "\n" ;
                  }
            }
            var exif = eval("("+ json[i]['exif'] +")");
            for(y in exif){
                elem += y + ":" + exif[y] + "\n" ;
            }
        }
        elem  += "</pre>";
        elem  += "<div class='tags'>";
        elem  += "<h4>tag</h4>";
        elem  +='<input type="text" value="#{tag}" style="float:left;" class="text_field" id="f_tag">'.replace('#{tag}',json[0]['tag']);
        elem  +='<input id="b_update_tag" type="button" style="float:left;" class="submit_button" value="update" onclick="this.disabled=true;updatetag(\'#{id}\');return false;">'.replace('#{id}',json[0]['_id']);
        elem  += "</div>";
        elem  += "</div>";
        elem = $(elem);
        page._set_mover_css2elem(elem,'highlight');
        
        $("#exifarea").html('').append(elem);
    },
    /* private helper */
    _set_mover_css2elem : function(elem, cstr ) {
        elem.mouseover(function(){$(this).toggleClass(cstr);});
        elem.mouseout(function(){$(this).toggleClass(cstr);});
    }
};
var qstringEscape = function(string){
    return string.replace("|",'<OR>');
};
var qstringUnEscape = function(string){
    return string.replace('%3COR%3E','|');
};
function updatetag(id){
    var tagvalue = $("#f_tag").val();
    server.update_tag(id,tagvalue);
}

// do search
function run1(p){
    if(!p) p = 1;
    var qstring = $('#query').val();
    if(qstring != ""){
        $('#grayout').toggle();
        server.search(qstringEscape(qstring),'1',p);
        stateHandle({kind:"qs",id:qstringEscape(qstring)},"?qs="+qstringEscape(qstring));

        history.pushState("", "", "?qs="+qstringEscape(qstring));
        page.chg_dirli_select("");
    }
    window.scroll(0,0);
    return false;
}
function run(p){
    run2(p);
}
function run2(p){
    if(!p) p = 1;
    if(qstring != ""){
        var qstring = $('#query').val();
        $('#grayout').toggle();
        server.search(qstringEscape(qstring),'2',p);
        stateHandle({kind:"qs",id:qstringEscape(qstring)},"?qs="+qstringEscape(qstring));
        page.chg_dirli_select("");
    }
//$(window).scrollTop(0);
$(window).scrollTop(0);
    return false;
}
function run3(p){
    if(!p) p = 1;
    if(qstring != ""){
        var qstring = $('#query').val();
        $('#grayout').toggle();
        server.search(qstringEscape(qstring),'3',p);
        stateHandle({kind:"qs",id:qstringEscape(qstring)},"?qs="+qstringEscape(qstring));
        page.chg_dirli_select("");
    }
    window.scroll(0,0);
    return false;
}
// reload dirs
function reload_dirs(){
    $('#grayout').toggle();
    server.dirs();
    return false;
}

// reload dir
function reload_dir(id){
    page.nowdirid = id;
    $('#grayout').toggle();
    $('#query').val('');
    $('#popup').fadeOut(0);
    page.chg_dirli_select(id);
    server.dir(id);
    stateHandle({kind:"dir",id:id},"?dir="+id);
    return false;
}

// display pupup
function display_thumb_m(id,path){
    $('#popup').fadeOut(0);
    page.chg_painli_select(id);
    server.exif(id);
    //  var elem = "<a href='#{href}' target='_blank'><img src='#{src}'></a>";
    var elem = "<a id='thumb_m' href='#{href}' target='_blank'><img src='#{src}' alt='img'></a>";
    elem = elem.replace('#{src}', server._prefix + "/image/thumb_m/" + id + "?qs=" /* + path*/);
    //    elem = elem.replace('#{href}', server._prefix + "/image/full/" + id + "?qs="  + path);
    elem = elem.replace('#{href}', "/photodb/image/full/" + id );
    //  elem = elem.replace('#{href}',server._prefix + "/image/full/" + id );
    elem = $(elem);
    page._set_mover_css2elem(elem,'highlight');
    $('#imgarea').html('').append(elem);
    $('#popup').fadeIn();
    return false;
}

var AppUtil = {
    isMsIE : /*@cc_on!@*/false,
    debug : function(s){
//        console.log(s);
    },
    applyToSystem : function(){
        String.prototype.r = String.prototype.replace;
    }
};


/* push state */
var stateDryRun = false;
function stateHandle(obj,path){
    if(!AppUtil.isMsIE){
        if(stateDryRun){
            stateDryRun = false;
        }else{
            history.pushState(obj,"",path);
        }
    }
}
function popStateHandler(e) {
    // revive from state object
    if(e.state.kind=="qs"){
        stateDryRun = true;
        $('#query').val(e.state.id);
        run();
    }
    if(e.state.kind=="dir"){
        stateDryRun = true;
        page.chg_dirli_select(e.state.id);
        reload_dir(e.state.id);
    }
}

function revive(location){
    // revive from requested uri
    if(location.search.match(/\?qs\=/)){
        // do search is need
        var qstring = location.search.replace('?qs=','');
        $('#query').val(qstringUnEscape(qstring));
        $('#echoarea').html(qstringUnEscape(qstring));
        run2();
    }
    if(location.search.match(/^\?dir\=/)){
        // do load dir is need
        var dirstring = location.search.replace('?dir=','');
        reload_dir(dirstring);
    }
}

// init
$(function(){
      $("#pain").html("<ul>");
      reload_dirs();
      // ui 
      $("header").click(function(){ $('#popup').fadeOut();});
      $("li").click(function(){ $('#popup').fadeOut();});
      
  });

$(function(){
      revive(location);
  });

$(function(){
      if (window.history && window.history.pushState) {
          $(window).bind("popstate", function(e){
                             popStateHandler(e.originalEvent);
                         });
      }
  });

/* debug */
$(function(){
      //display_thumb_m("4e89afec9ef02f75d2000d29")     ;
  });

