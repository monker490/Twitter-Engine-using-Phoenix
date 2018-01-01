defmodule Project5Web.ServerChannel do
    require Logger
    use Phoenix.Channel
    use GenServer
    
    def join("engine:server", _payload, socket) do
      {:ok, socket}
    end

    def handle_in("register", list, socket) do
      Project5Web.ChannelMonitor.addUser(Enum.at(list,0),Enum.at(list,1),Enum.at(list,2))
      Project5Web.ChannelMonitor.flushtweet(Enum.at(list,0))
      {:noreply,socket}
    end

    def handle_in("follow", list, socket) do
      Project5Web.ChannelMonitor.addFollower(Enum.at(list,0),Enum.at(list,1))
      {:noreply,socket}
    end

    def handle_in("tweet", list, socket) do #list has the form [user,tweet] || [user,tweet,originalcreator]
      Project5Web.ChannelMonitor.distributeTweet(list)
      if (Enum.count(list) == 2) do
        Project5Web.ChannelMonitor.parseText(list)
      end
      {:noreply,socket}
    end

    def handle_in("disconnect", user, socket) do 
      Project5Web.ChannelMonitor.changestatus(user)
      {:noreply,socket}
    end

    def handle_in("retweet",user, socket) do
      Project5Web.ChannelMonitor.retweet(user)
      {:noreply,socket}
    end

    def handle_in("search",args, socket) do
      Project5Web.ChannelMonitor.search()
      {:noreply,socket}
    end

    def handle_in("information",args, socket) do
      Project5Web.ChannelMonitor.information()
      {:noreply,socket}
    end

    def handle_in("flush", user, socket) do
      Project5Web.ChannelMonitor.flushtweet(user)
      {:noreply,socket}
    end
    
  end