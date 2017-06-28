package ;

import js.Browser.*;
import js.html.*;
import tink.state.*;
using tink.CoreApi;

typedef User = {
  var login(default, never):String;
  var html_url(default, never):String;
  var avatar_url(default, never):String;
}

class Example {
  
  static function clickTrigger(selector:String) {
    var ret = new State(0);
    document.querySelector(selector).addEventListener('click', function () ret.set(ret.value + 1));
    return ret.observe();
  }

  static function loadJson<A>(url:String):Promise<A>
    return Future.async(function (cb) {
      var req = new haxe.Http(url);
      req.onData = function (data) {
        cb(Success(haxe.Json.parse(data)));
      }
      req.onError = function (error) {
        cb(Failure(new Error(error)));
      }
      req.request();
    });

  static function main() {
     
    var refreshClickStream = clickTrigger('.refresh');
    var close1ClickStream = clickTrigger('.close1');
    var close2ClickStream = clickTrigger('.close2');
    var close3ClickStream = clickTrigger('.close3');
     
    var requestStream = refreshClickStream
      .map(function(_) {
        var randomOffset = Math.floor(Math.random()*500);
        return 'https://api.github.com/users?since=$randomOffset';
      });
     
    var responseStream = requestStream.mapAsync(loadJson);
     
    function createSuggestionStream(closeClickStream:Observable<Int>) 
      return closeClickStream.combine(responseStream, function (_, users:Promised<Array<User>>) return switch users {
        case Done(listUsers): listUsers[Math.floor(Math.random()*listUsers.length)];
        default: null;
      });
     
    var suggestion1Stream = createSuggestionStream(close1ClickStream);
    var suggestion2Stream = createSuggestionStream(close2ClickStream);
    var suggestion3Stream = createSuggestionStream(close3ClickStream);
     
    function renderSuggestion(suggestedUser, selector) {
      var suggestionEl = document.querySelector(selector);
      if (suggestedUser == null) {
        suggestionEl.style.visibility = 'hidden';
      } 
      else {
        suggestionEl.style.visibility = 'visible';
        var usernameEl:AnchorElement = cast suggestionEl.querySelector('.username');
        usernameEl.href = suggestedUser.html_url;
        usernameEl.textContent = suggestedUser.login;
        var imgEl:ImageElement = cast suggestionEl.querySelector('img');
        imgEl.src = "";
        imgEl.src = suggestedUser.avatar_url;
      }
    }
     
    suggestion1Stream.bind(function (suggestedUser) {
      renderSuggestion(suggestedUser, '.suggestion1');
    });
    
    suggestion2Stream.bind(function (suggestedUser) {
      renderSuggestion(suggestedUser, '.suggestion2');
    });
    
    suggestion3Stream.bind(function (suggestedUser) {
      renderSuggestion(suggestedUser, '.suggestion3');
    });
    
  }
}