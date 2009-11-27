%%% 
%%% Simple STUN Client with Erlang
%%%

-module(stun_client).

-export([
	stun_timestamp/0,
	get_mapped_address/3,
	test/0
	]).

%%% Magic cookie field MUST contain the fixed value 0x2112A442 ...
%%% - RFC 5389
-define(MAGIC_COOKIE, 16#2112A442).

%% STUN Message Type.
-define(STUN_TYPE_BINDING_REQUEST, 16#0001).
-define(STUN_TYPE_BINDING_RESPONSE, 16#0101).

%% STUN Attribute.
-define(STUN_ATTRIBUTE_MAPPED_ADDRESS, 16#0001).
-define(STUN_ATTRIBUTE_RESPONSE_ADDRESS, 16#0002).

-define(STUN_PORT, 3478).
-define(STUN_PROTO, udp).

stun_timestamp() ->
	{Megasec, Sec, _} = now(),
	Megasec * 1000000 + Sec.

get_mapped_address(Proto, Host, Count) when is_atom(Proto), is_list(Host), is_integer(Count) ->
	SocketOpts = [{reuseaddr, true}, {active, true}, binary],
	TimeStamp = stun_timestamp(),
	io:format("Connecting to ~s:~p...", [Host, ?STUN_PORT]),

	{ok, Socket} = gen_udp:open(0, SocketOpts),

	StunPackage = <<16#0001:16/big-unsigned,
	0:16/big-unsigned,
	?MAGIC_COOKIE:32/big-unsigned,
	TimeStamp:96/big-unsigned
	>>,
	
	gen_udp:send(Socket, Host, ?STUN_PORT, StunPackage),

	receive 
	{udp, Socket, RcvHost, RcvPort, Packet} when Proto == udp ->
		io:format("Done!");

	Unknown ->
		io:format("Oops.")

	after 300 ->
		io:format("Timeout. ~n"),
		error
	
	end.
%%
%% Test code.
%%
test() ->
	io:format("stun_timestamp/1 - 1\n"),
	Timestamp1 = stun_timestamp(),
	true = is_integer(Timestamp1),

	io:format("get_mapped_address/2 - 2\n"),
	Server = "127.0.0.1",
	true = get_mapped_address(udp, Server, 1),

	ok.

