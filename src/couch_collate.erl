% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

-module(couch_collate).

-export([init/0]).
-export([collate/2, collate/3]).

-on_load(init/0).

-type collate_options() :: [nocase].
-export_type([collate_options/0]).

init() ->
    PrivDir = case code:priv_dir(?MODULE) of
        {error, _} ->
            EbinDir = filename:dirname(code:which(?MODULE)),
            AppPath = filename:dirname(EbinDir),
            filename:join(AppPath, "priv");
        Path ->
            Path
    end,
    NumScheds = erlang:system_info(schedulers),
    Arch = erlang:system_info(system_architecture),
    (catch erlang:load_nif(filename:join([PrivDir, Arch, ?MODULE]),
                           NumScheds)),
    case erlang:system_info(otp_release) of
        "R13B03" -> true;
        _ -> ok
    end.

%% @doc compare 2 string, result is -1 for lt, 0 for eq and 1 for gt.
-spec collate(binary(), binary()) -> 0 | -1 | 1.
collate(A, B) ->
    collate(A, B, []).

-spec collate(binary(), binary(), collate_options()) -> 0 | -1 | 1.
collate(A, B, Options) when is_binary(A), is_binary(B) ->
    HasNoCase = case lists:member(nocase, Options) of
        true -> 1; % Case insensitive
        false -> 0 % Case sensitive
    end,
    do_collate(A, B, HasNoCase).

%% @private

do_collate(BinaryA, BinaryB, 0) ->
    collate_nif(BinaryA, BinaryB, 0);
do_collate(BinaryA, BinaryB, 1) ->
    collate_nif(BinaryA, BinaryB, 1).

collate_nif(_BinaryA, _BinaryB, _HasCase) ->
    exit(couch_collate_not_loaded).
