defmodule Project5.ClientSimulator do
    use GenServer
    require Logger
    alias Phoenix.Channels.GenSocketClient
    @behaviour GenSocketClient
    

    def init([url,user]) do 
        {:connect, url,[], [userName = user, password = user <> "password", myTweets = [], myFeed = %{}, myFollowers = [], myFollowing = [],reTweets = %{}]}
    end
    
    def start_link(args) do
        GenSocketClient.start_link(__MODULE__, Phoenix.Channels.GenSocketClient.Transport.WebSocketClient, ["ws://localhost:4000/socket/websocket","UserY"], [], name: :UserY)
        # GenSocketClient.start_link(__MODULE__, Phoenix.Channels.GenSocketClient.Transport.WebSocketClient, ["ws://localhost:4000/socket/websocket"], [], name: :server)
    end

    

    def handle_connected(transport, state) do
        Logger.info("connected")
        # Logger.info(:erlang.pid_to_list(transport))
        GenSocketClient.join(transport, "engine:server")
        {:ok, state}
    end

    def handle_disconnected(reason, state) do
        Logger.error("disconnected: #{inspect reason}")
        Process.send_after(self(), :connect, :timer.seconds(1))
        {:ok, state}
    end

    def handle_joined(topic, _payload, _transport, state) do
        Logger.info("joined the topic #{topic}")
        # Logger.info(_transport)
        GenSocketClient.push(_transport,"engine:server", "register", [Enum.at(state,0), Enum.at(state,1), 1])
        GenSocketClient.push(_transport,"engine:server", "register", ["UserZ", "UserZpassword", 1])
        GenSocketClient.push(_transport,"engine:server", "register", ["UserX", "UserXpassword", 1])
        GenSocketClient.push(_transport,"engine:server", "follow", ["UserZ",Enum.at(state,0)])
        GenSocketClient.push(_transport,"engine:server", "follow", [Enum.at(state,0),"UserZ"])
        GenSocketClient.push(_transport,"engine:server", "tweet", [Enum.at(state,0),"This is a tweet"])
        GenSocketClient.push(_transport,"engine:server", "tweet", [Enum.at(state,0),"This is a #hashtag tweet"])
        GenSocketClient.push(_transport,"engine:server", "tweet", [Enum.at(state,0),"This is a @UserX tweet"])
        GenSocketClient.push(_transport,"engine:server", "retweet", [%{}])
        GenSocketClient.push(_transport,"engine:server", "search", [%{}])
        
        # IO.gets ("")
        GenSocketClient.push(_transport,"engine:server", "information",[])
        
        {:ok, state}
    end

    

    def handle_join_error(topic, payload, _transport, state) do
        Logger.error("join error on the topic #{topic}: #{inspect payload}")
        {:ok, state}
    end
    
    def handle_channel_closed(topic, payload, _transport, state) do
        Logger.error("disconnected from the topic #{topic}: #{inspect payload}")
        GenSocketClient.push(_transport,"engine:server", "disconnect",["UserZ"]) #logout
        Process.send_after(self(), {:join, topic}, :timer.seconds(1))
        {:ok, state}
    end

    def handle_message(topic, event, payload, _transport, state) do
        Logger.warn("message on topic #{topic}: #{event} #{inspect payload}")
        {:ok, state}
    end

    def handle_reply(topic, _ref, payload, _transport, state) do
        Logger.warn("reply on topic #{topic}: #{inspect payload}")
        {:ok, state}
    end

    def handle_info(:connect, _transport, state) do
        Logger.info("connecting")
        {:connect, state}
    end
    
    def handle_info({:join, topic}, transport, state) do
        Logger.info("joining the topic #{topic}")
        case GenSocketClient.join(transport, topic) do
            {:error, reason} ->
            Logger.error("error joining the topic #{topic}: #{inspect reason}")
            Process.send_after(self(), {:join, topic}, :timer.seconds(1))
            {:ok, _ref} -> :ok
    end

    {:ok, state}
    end
    
    def handle_info(message, _transport, state) do
        Logger.warn("Unhandled message #{inspect message}")
        {:ok, state}
    end

    

end