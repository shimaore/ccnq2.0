%%  mod_ecouch.erl -- Yaws module to start the eCouch application
%%  Copyright (C) 2009 Stephane Alnet
%%
%%  This program is free software: you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation, either version 3 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with this program.  If not, see <http://www.gnu.org/licenses/>.


%% Based on http://yoan.dosimple.ch/blog/2008/06/10/
%% DEPLOY the resulting beam AS /usr/lib/yaws/ebin/mod_ecouch.beam


-module(mod_ecouch).
-author('stephane@shimaore.net').

-export([start/0,stop/0]).

start() ->
  application:start(inets),
  application:start(ecouch).

stop() ->
  application:stop(ecouch),
  application:stop(inets).
