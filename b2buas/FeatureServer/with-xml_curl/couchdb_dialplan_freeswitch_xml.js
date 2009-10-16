// DEPLOY AS a new CouchDb view called freeswitch/xml (the name is hardcoded in dialplan.yaws)
//
// This function is used by CouchDB in order to generate on-the-fly XML
// for FreeSwitch.
//

function(doc) {

  // extension and context are always required.
  var key = doc.extension+'@'+doc.context;

  var xml_header =
    "<context name=\""+doc.context+"\">" +
    "<extension name=\""+doc.extension+"\">" +
    "<condition field=\"destination_number\" expression=\"^("+doc.extension+")$\">";

  var xml_footer =
    "</condition></extension></context>";

  xml_header +=
    "<action application=\"export\" data=\"sip_req_user=$1\"/>" +
    "<action application=\"set\" data=\"did_number=$1\"/>";

  if(doc.domain) {
    xml_header +=
      "<action application=\"set\" data=\"target_domain=\""+doc.domain+"\"/>";
  }

  if(doc.accountcode) {
    xml_header +=
      "<action application=\"export\" data=\"accountcode="+doc.accountcode+"\"/>";
  }

  if(doc.caller_id_name) {
    xml_header +=
      "<action application=\"set\" data=\"origination_caller_id_name="+doc.caller_id_name+"\"/>";
  }

  if(doc.caller_id_number) {
    xml_header +=
      "<action application=\"set\" data=\"origination_caller_id_number="+doc.caller_id_number+"\"/>";
  }

  if(doc.ignore_early_media) {
    xml_header +=
      "<action application=\"set\" data=\"ignore_early_media="+doc.ignore_early_media+"\"/>";
  }

  if(doc.instant_ringback) {
    xml_header +=
      "<action application=\"set\" data=\"instant_ringback="+doc.instant_ringback+"\"/>";
  }

  if(doc.call_timeout) {
    xml_header +=
      "<action application=\"set\" data=\"call_timeout="+doc.call_timeout+"\"/>";
  }

  // doc.followme is an array of arrays of destinations.
  // The calls described in doc.followme are placed sequentially (in the first level of array)
  // and/or in parallel (in the second level of array).
  // [ [ // -- first sequence
  //     {"enabled":1,"number":"1...", "sofia_host":"..", "sofia_profile":>"...","params":{...} },
  //     {"enabled":0,"number":"2...", "sofia_profile":"...","params":{...} }
  //   ],
  //   [ // -- second sequence (if none above responded)
  //   ],
  // ]

  // target is   sofia/${sofia_profile}/${number}@${sofia_host}
  //    only sofia_host is optional
  // "params" is an hash of optional parameters:
  //    leg_delay_start      (integer)    delay before initiating the call
  //    originate_timeout    (integer)    timeout for any reply (dead target detection)
  //    ignore_early_media   true/false   ignore any early media (probably disables leg_progress_timeout)
  //    leg_progress_timeout (integer)    timeout for any media on this leg
  //    leg_timeout          (integer)    timeout until answer
  //    leg_confirm          (integer)    if present, confirm the call (value doesn't matter)
  //  

  if(doc.followme)
  {
    function non_empty(element,index,array) { return element.length > 0; };

    var bypass_media = ",bypass_media=true";

    var target =
      doc.followme.map( function(t){
        return t.map( function(target){

          if(!target.enabled) return ''; // these get removed out by "filter"
          if(!target.number)  return ''; // these get removed out by "filter"
          if(!target.sofia_profile)  return ''; // these get removed out by "filter"

          var params = new Array;
          for (var n in target.params)
          {
            params.push(n+"="+target.params[n]);
            if(n=="leg_confirm") bypass_media = "";
          }
          var sofia = "sofia/" + target.sofia_profile + "/" + target.number;
          if(target.sofia_host) sofia += "@" + target.sofia_host;

          if(params.length > 0)
          { return "["+params.join(",")+"]"+sofia; }
          else
          { return sofia; }

        } ).filter(non_empty).join(',')
      } ).filter(non_empty).join('|');

    if(target.length == 0) return;

    var xml =
      // "<action application=\"ring_ready\"/>"+
      "<action application=\"set\" data=\"continue_on_fail=NORMAL_TEMPORARY_FAILURE,USER_BUSY,NO_ANSWER,NO_ROUTE_DESTINATION\"/>" +
      "<action application=\"bridge\" data=\"{hangup_after_bridge=true,group_confirm_key=exec,group_confirm_file=javascript confirm.js"+bypass_media+"}"+target+"\"/>";
    emit(key,xml_header+xml+xml_footer);
    return;
  }
}

