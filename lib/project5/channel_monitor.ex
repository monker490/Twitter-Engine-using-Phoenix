defmodule Project5Web.ChannelMonitor do
    use GenServer
    require Logger
    alias Phoenix.Channels.GenSocketClient
    @behaviour GenSocketClient
    
    

    def init(args) do
        userinfo = %{} 
        subsmap = %{}
        userconnection = %{}
        hashtags = %{}
        storedtweets = %{}
        storedretweets = %{}
        {:ok,[userinfo,subsmap,userconnection,hashtags,storedtweets,storedretweets]}
    end

    def start_link(args) do
      # Logger.info("Hello")
      # GenSocketClient.start_link(__MODULE__, Phoenix.Channels.GenSocketClient.Transport.WebSocketClient, "ws://localhost:4000/socket/websocket", [], name: :server)
      GenServer.start_link(__MODULE__,[],name: :server )
    end

    def handle_connected(transport, state) do
      Logger.info("server connected")
      GenSocketClient.join(transport, "engine:server")
      {:ok, state}
  end

  def handle_disconnected(reason, state) do
      Logger.error("disconnected: #{inspect reason}")
      Process.send_after(self(), :connect, :timer.seconds(1))
      {:ok, state}
  end

  def handle_joined(topic, _payload, _transport, state) do
      Logger.info("server online in #{topic}")
      # Logger.info(_transport)
      {:ok, state}
  end


    def addUser(username, password,status) do
        list = [username, password, status]  
        GenServer.cast(:server,{:registerNewUser,list})
        
      end
      
      def addFollower(user,follower) do 
        list = [user,follower]
        GenServer.cast(:server,{:follow,list})
        # GenSocketClient.push(transport,"engine:server","follow",list)
      end

      def distributeTweet(tweet) do
        # Logger.info("does it come here?")
        GenServer.cast(:server,{:distribute,tweet})
        
        # GenSocketClient.push(transport,"engine:server","distribute",tweet)
      end

      def retweet(user) do
        GenServer.cast(:server,{:reTweeter,user})
      end

      def flushtweet(user) do
        GenServer.cast(:server,{:flush,user})
        # GenSocketClient.push(transport,"engine:server","flush",transport)
      end

      def changestatus(user) do
        GenServer.cast(:server,{:changestatus,user})
        # GenSocketClient.push(Enum.at(list,1),"engine:server","changestatus",list)
      end

      def search() do
        GenServer.cast(:server,{:searchtags})
        # GenSocketClient.push(transport,"engine:server","searchtags",transport)
      end
      
      def information() do
        GenServer.call(:server,{:info})
        # GenSocketClient.call(transport,"engine:server","info",transport)
      end      
      

      def handle_cast({:registerNewUser,list},state) do #list has the form [username,password,connection status]
      # count = Enum.at(state,6) + 1
      # state = List.replace_at(state,6,count)
      temp = Enum.at(state,0)
      # IO.inspect temp
      temp2 = Enum.at(state,1)
      temp3 = Enum.at(state,2)
      if (Map.has_key?(temp,Enum.at(list,0))) do
        # IO.puts "user already exists"
        {:noreply,state}
      else
        # IO.puts "user added"
        # IO.puts Enum.at(list,0)
        # IO.puts Enum.at(list,1)
        temp = Map.put(temp,Enum.at(list,0),Enum.at(list,1)) #user added to database with password
        temp2 = Map.put(temp2,Enum.at(list,0),[]) #empty follower list created
        temp3 = Map.put(temp3,Enum.at(list,0),Enum.at(list,2)) #Connection status
        state = List.replace_at(state,0,temp)
        state = List.replace_at(state,1,temp2)
        state = List.replace_at(state,2,temp3)
        {:noreply,state}
      end
    end
    

    def handle_cast({:follow,list},state) do #list has the form [user,follower]
      # count = Enum.at(state,6) + 1
      # state = List.replace_at(state,6,count)
      temp = Enum.at(state,1)
      if (Map.has_key?(temp,Enum.at(list,0))) do
        followlist = Map.get(temp,Enum.at(list,0))
        followlist = followlist ++ [Enum.at(list,1)]
        temp = Map.put(temp,Enum.at(list,0),followlist)
        state = List.replace_at(state,1,temp)
        #IO.inspect Enum.at(state,1)
        # IO.puts "ho gaya"
        {:noreply,state}  
      else
        IO.puts "no such user"
        {:noreply,state}
      end
    end
  
    def handle_cast({:distribute,tweet},state) do
      tweets = Enum.at(state,4)
      retweets = Enum.at(state,5)
      temp = Enum.at(state,1)
      followlist = Map.get(temp,Enum.at(tweet,0)) #finds all followers of the tweeter
      Enum.each(followlist, fn(z)-> 
        if (Enum.count(tweet)==2) do
          list = tweet ++ [z]
          GenServer.cast(:server,{:storeTweet,list})
        else
          # IO.inspect tweet
          list = tweet ++ [z]
          IO.puts "RETWEET"
          IO.inspect list #
          # GenServer.cast(:server,{:rtStore,[Enum.at(list,0),Enum.at(list,1),Enum.at(list,2),Enum.at(list,3)]})
        end
      end)
      {:noreply,state}
    end

    
    def handle_cast({:flush,user},state) do
      # count = Enum.at(state,6) + 1
      # state = List.replace_at(state,6,count)
      # connstatus = Enum.at(state,2)
      # keylist = Map.keys(connstatus)
      storedtweets = Enum.at(state,4)
      storedretweets = Enum.at(state,5)
      x = Map.get(storedtweets,user)
      y = Map.get(storedretweets,user)
      # Logger.info x
      # Logger.info y
      {:noreply,state}
    end

  
    def handle_cast({:changestatus,user},state) do
      # count = Enum.at(state,6) + 1
      # state = List.replace_at(state,6,count)
      
      statusmap = Enum.at(state,2)
      # Enum.each(user, fn(x)->
        if (Map.get(statusmap,user) == 1) do
          statusmap = Map.put(statusmap,user,0)
          # IO.puts "hello"
        else
          statusmap = Map.put(statusmap,user,1)
        end
      # end)
      # IO.inspect statusmap
      state = List.replace_at(state,2,statusmap)
      {:noreply,state}
    end

    def handle_cast({:searchtags},state) do
      # count = Enum.at(state,6) + 1
      # state = List.replace_at(state,6,count)
      tags = Enum.at(state,3)
      if(Enum.count(tags)>0) do
        keys = Map.keys(tags)
        list = Map.get(tags,Enum.random(keys))
        IO.puts "SEARCH OUPTUT:"
        IO.inspect Enum.random(list)
      end
      {:noreply,state}
      
    end


    def handle_cast({:storeTweet,list},state) do #list has the form [user,tweet,receiver]
    # IO.puts "idhar aa jaa raani"
    # count = Enum.at(state,6) + 1
    # state = List.replace_at(state,6,count)
    storage = Enum.at(state,4)
    if(Map.has_key?(storage,Enum.at(list,2))) do 
      alreadystored = Map.get(storage,Enum.at(list,2)) #get tweets that need to be deliverd to user
      alreadystored = alreadystored ++ [{Enum.at(list,0),Enum.at(list,1)}]
    else
      # IO.puts "storing"
      alreadystored = [{Enum.at(list,0),Enum.at(list,1)}]
    end
    storage = Map.put(storage,Enum.at(list,2),alreadystored)
    #IO.inspect storage
    state = List.replace_at(state,4,storage)
    {:noreply,state}

  end

  def handle_call({:rtStore,[retweeter,retweet,originalcreator,receiver]},state) do #list has the form [retweeter,tweet,original creator,receiver]
    retweets = Enum.at(state,5)
    # IO.inspect Enum.at(tweet,0)
    # IO.inspect Enum.at(tweet,1)
    # IO.inspect Enum.at(tweet,2)
    # IO.puts "idhar hai????????????????????????????????/"
    if(Map.has_key?(retweets,receiver)) do 
        retweetlist = Map.get(retweets,receiver) #get all tweets that receiver has
        retweetlist = retweetlist ++ [{originalcreator,retweeter,retweet}]
    else
        # IO.puts "Idhar"
        retweetlist = [{originalcreator,retweeter,retweet}]
    end
    retweets = Map.put(retweets,receiver,retweetlist)
    state = List.replace_at(state,5,retweets)
    {:noreply,state}

  end

  def handle_cast({:reTweeter,user},state) do
    # IO.puts user
    alltweets = Enum.at(state,4)
    # IO.inspect Map.has_key?(alltweets,user)
    user = Enum.random(Map.keys(alltweets))
    tweetlist = Map.get(alltweets,user) #Get all tweets received by the user
    # IO.inspect tweetlist
    if (Enum.count(tweetlist)>0) do
        {retweetHim, retweet} = Enum.random(tweetlist)
        # tweet = Enum.random(Map.get(tweetlist,retweetHim))
        # IO.puts tweet
        # IO.puts retweetHim
        # GenServer.cast(:server,{:distribute,[user,retweet,retweetHim]})
        distributeTweet([user,retweet,retweetHim])
    end
    {:noreply,state}
  end

    def parseText(tweet) do #tweet has the form [user,tweet]
    text = Enum.at(tweet,1)
    text = String.split(text," ")
    Enum.each(text, fn(word) -> 
      if (String.first(word) == "#" && String.length(word) > 1) do ##NEED TO DO THE MAGIC HERE
        # IO.inspect word
        hashTweet = tweet ++ [word]
        # IO.inspect hashTweet
        GenServer.cast(:server,{:addHashtag,hashTweet})
      end
      if (String.first(word) == "@" && String.length(word) > 1) do
        word = String.slice(word,1..String.length(word)-1)
        #IO.inspect word
        # GenServer.cast(String.to_atom(word),{:receive,tweet})
        list = tweet ++ [word]
        GenServer.cast(:server,{:storeTweet,list})
      end
    end)
  end

  
    def handle_cast({:addHashtag,hashTweet},state) do #hashTweet has the form [user,tweet,hashtag]
    # count = Enum.at(state,6) + 1
    # state = List.replace_at(state,6,count)  
    hashTags = Enum.at(state,3)
      if (Map.has_key?(hashTags,Enum.at(hashTweet,2))) do
        hashlist = Map.get(hashTags,Enum.at(hashTweet,2))
        hashlist = hashlist ++ [{Enum.at(hashTweet,0),Enum.at(hashTweet,1)}] ##make a tuple {username,tweet} and it to the corresponding haslist
      else
        hashlist = [{Enum.at(hashTweet,0),Enum.at(hashTweet,1)}]
      end
        hashTags = Map.put(hashTags,Enum.at(hashTweet,2),hashlist)
        state = List.replace_at(state,3,hashTags)
        {:noreply,state}
    end

    def handle_call({:info}, _from ,state) do
      # IO.puts "AAJ HUM PRINT KARENGE"
      IO.inspect Enum.at(state,0) ##Userinfo of the form username =>password
      IO.inspect Enum.at(state,1) ##Subscribersmap map of all user and the people that follow them user => [follower1,follower2]
      IO.inspect Enum.at(state,2) ##connectioninfo stored as user => 1 if user is online
      IO.inspect Enum.at(state,3) ##hashtags hashtags stored in the form #hashatag => {tweeter,tweet}
      IO.inspect Enum.at(state,4) ##tweetstorage for all users with the form user => [{followinghim,histweet},{followinghim,hisothertweet},{followingher,hertweet}]
      # IO.inspect Enum.at(state,5) ##retweetstorage for all users with the form user => [{originalcreater,followinghim,tweet},{originalcreater,followinghim,othertweet},{originalcreater,followingher,tweet}]
      {:reply,state,state}
    end
    
end