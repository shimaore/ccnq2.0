//  confirm.js -- Javascript application for FreeSwitch to implement call confirmation
//  Copyright (C) 2009 Stephane Alnet
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.


// ------------- see http://blog.shimaore.net/2009/03/better-followme-for-freeswitch.html ----------

console_log("info", "Destination: "+ session.destination + "\n");
if(!session.getVariable('leg_confirm'))
{
  console_log("info", "No need to confirm, connect the call!\n");
  exit();
}

var confirmed = false;
var confirmation_digit = "1";
var try_count = 6;
var prompt_file = "connect-to-caller-press-1.wav";

function onInput( session, type, data, arg ) {
  if ( type == "dtmf" ) {
    console_log( "info", "Got digit " + data.digit + "\n" );
    if ( data.digit == confirmation_digit ) {
      confirmed = true;
      console_log( "info", "Confirming session..\n" );
      return(false);
    }
  }
  return(true);
}

console_log("info", "Trying to obtain the session\n");
if ( session.ready() ) 
{
  console_log("info", "Trying to answer\n");
  session.answer();
  console_log("info", "Trying to flush digits\n");
  session.flushDigits();
  console_log("info", "Starting confirmation\n");
  var count = try_count;
  while( session.ready() && ! confirmed && count-- > 0 )
  {
    session.execute("sleep","200");
    session.streamFile( prompt_file, onInput );
  }
  if( ! confirmed )
  {
    console_log("info", "Not confirmed\n");
    session.hangup();
  }
  else
  {
    console_log("info", "Confirmed\n");
  }
}
else
{
  console_log("info", "Session is not ready.\n");
}
