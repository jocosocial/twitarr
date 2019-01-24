Twitarr::Application.routes.draw do
  root 'home#index'

  # get 'time', to: 'home#time'

  # post 'login', to: 'user#login'

  # get 'alerts', to: 'alerts#index'
  # get 'alerts/check', to: 'alerts#check'

  # get 'announcements', to: 'announcements#index'

  # get 'search/:text', to: 'search#search'
  # get 'search_users/:text', to: 'search#search_users'
  # get 'search_tweets/:text', to: 'search#search_tweets'
  # get 'search_forums/:text', to: 'search#search_forums'
  # get 'search_events/:text', to: 'search#search_events'

  # get 'user/username'
  # get 'user/logout'
  # get 'user/starred'
  # get 'user/autocomplete'
  # post 'user/save_profile'
  # get 'user/profile/:username', to: 'user#show'
  # get 'user/profile/:username/star', to: 'user#star'
  # get 'user/profile/:username/vcf', to: 'user#vcard', format: false
  # post 'user/profile/:username/personal_comment', to: 'user#personal_comment'

  # get 'admin/users'
  # get 'admin/users/:text', to: 'admin#user'
  # post 'admin/activate'
  # post 'admin/reset_password'
  # post 'admin/update_user'
  # post 'admin/new_announcement'
  # get 'admin/announcements'
  # post 'admin/upload_schedule'

  # resources :forums, except: [:show, :destroy, :edit, :new] do
  #   collection do
  #     get ':page', to: 'forums#page'
  #     get 'thread/:id', to: 'forums#show'
  #     get 'thread/:id/:page', to: 'forums#show'
  #     post 'new_post'
  #     put 'thread/:forum_id/:forum_post_id', to: 'forums#update'
  #     delete 'thread/:forum_id/:forum_post_id', to: 'forums#delete_post'
  #   end
  # end

  # resources :seamail, except: [:destroy, :edit, :new] do
  #   collection do
  #     post 'new_message'
  #   end
  # end
  # put 'seamail/:id/recipients', to: 'seamail#recipients'

  # get 'stream/star/:page', to: 'stream#star_filtered_page'
  # get 'stream/:page', to: 'stream#page'
  # post 'stream', to: 'stream#create'
  # post 'tweet/edit/:id', to: 'stream#edit'
  # get 'tweet/like/:id', to: 'stream#like'
  # get 'tweet/unlike/:id', to: 'stream#unlike'
  # get 'tweet/destroy/:id', to: 'stream#destroy'
  # get 'tweet/:id', to: 'stream#get'

  # post 'photo/upload'
  # get 'photo/small_thumb/:id', to: 'photo#small_thumb'
  # get 'photo/medium_thumb/:id', to: 'photo#medium_thumb'
  # get 'photo/full/:id', to: 'photo#full'

  # get 'location/autocomplete/:query', to: 'location#auto_complete'
  # get 'location', to: 'location#index'
  # post 'location', to: 'location#create'
  # delete 'location/:name', to: 'location#delete'

  # resources :event, except: [:index, :edit, :new] do
  #   collection do
  #     get 'mine/:day', to: 'event#mine'
  #     get 'all/:day', to: 'event#all'
  #     get 'csv'
  #   end
  #   member do
  #     post 'follow'
  #     post 'unfollow'
  #     get 'ical'
  #   end
  # end

  namespace :api do
    namespace :v2 do
      resources :event, only: [:index, :update, :destroy]
      get 'event/:id', to: 'event#show'
      get 'event/:id/ical', to: 'event#ical'
      post 'event/:id/favorite', to: 'event#follow'
      delete 'event/:id/favorite', to: 'event#unfollow'
      get 'event/mine/:day', to: 'event#mine'
      get 'event/all/:day', to: 'event#all'

      get 'forums', to: 'forums#index'
      post 'forums', to: 'forums#create'
      get 'forums/thread/:id', to: 'forums#show'
      post 'forums/thread/:id', to: 'forums#new_post'
      post 'forums/thread/:id/like/:post_id', to: 'forums#like'
      delete 'forums/thread/:id/like/:post_id', to: 'forums#unlike'
      get 'forums/thread/:id/like/:post_id', to: 'forums#show_likes'
      post 'forums/thread/:id/react/:post_id/:type', to: 'forums#react'
      delete 'forums/thread/:id/react/:post_id/:type', to: 'forums#unreact'
      get 'forums/thread/:id/react/:post_id', to: 'forums#show_reacts'

      resources :stream, only: [:new, :create]
      get 'stream', to: 'stream#index'
      get 'stream/:start', to: 'stream#index'
      get 'stream/m/:query', to: 'stream#view_mention'
      get 'stream/h/:query', to: 'stream#view_hash_tag'

      get 'thread/:id', to: 'stream#show'
      get 'tweet/:id', to: 'stream#get'
      post 'tweet/:id', to: 'stream#update'
      delete 'tweet/:id', to: 'stream#delete'
      get 'tweet/:id/like', to: 'stream#show_likes'
      post 'tweet/:id/like', to: 'stream#like'
      delete 'tweet/:id/like', to: 'stream#unlike'
      get 'tweet/:id/react', to: 'stream#show_reacts'
      post 'tweet/:id/react/:type', to: 'stream#react'
      delete 'tweet/:id/react/:type', to: 'stream#unreact'

      post 'user/new', to: 'user#new'
      get 'user/new_seamail', to: 'user#new_seamail'
      delete 'user/mentions', to:'user#reset_mentions'
      get 'user/mentions', to:'user#mentions'
      get 'user/auth', to: 'user#auth'
      post 'user/auth', to: 'user#auth'
      post 'user/security_question', to: 'user#security_question'
      post 'user/reset_password', to: 'user#reset_password'
      get 'user/logout', to: 'user#logout'
      post 'user/logout', to: 'user#logout'
      get 'user/whoami', to: 'user#whoami'
      get 'user/profile', to: 'user#whoami'
      post 'user/profile', to: 'user#update_profile'
      get 'user/profile/:username', to: 'user#show'
      get 'user/profile/:username/star', to: 'user#star'
      post 'user/profile/:username/personal_comment', to: 'user#personal_comment'
      get 'user/autocomplete/:username', to: 'user#autocomplete'
      get 'user/view/:username', to: 'user#show'
      get 'user/starred', to: 'user#starred'
      get 'user/photo/:username', to: 'user#get_photo'
      post 'user/photo', to: 'user#update_photo'
      delete 'user/photo', to: 'user#reset_photo'

      get 'hashtag/repopulate', to: 'hashtag#populate_hashtags'
      get 'hashtag/ac/:query', to: 'hashtag#auto_complete'

      get 'search/all/:text', to: 'search#all'
      get 'search/users/:text', to: 'search#users'
      get 'search/tweets/:text', to: 'search#tweets'
      get 'search/forums/:text', to: 'search#forums'
      get 'search/events/:text', to: 'search#events'
      get 'alerts', to: 'alerts#index'
      get 'alerts/check', to: 'alerts#check'

      resources :seamail, except: [:destroy, :edit, :new], :defaults => { :format => 'json' }
      get 'seamail_threads', to: 'seamail#threads'
      post 'seamail/:id/', to: 'seamail#new_message'
      # post 'seamail/:id/recipients', to: 'seamail#recipients'

      get 'text/:filename', to: 'text#index'
      get 'time', to: 'text#time'
      get 'reactions', to: 'text#reactions'

      resources :photo, only: [:index, :create, :destroy, :update, :show], :defaults => { :format => 'json' }
      get 'photo/small_thumb/:id', to: 'photo#small_thumb'
      get 'photo/medium_thumb/:id', to: 'photo#medium_thumb'
      get 'photo/full/:id', to: 'photo#full'

      get 'admin/users', to: 'admin#users'
      get 'admin/users/:username', to: 'admin#user'
      post 'admin/users/:username', to: 'admin#update_user'
      post 'admin/users/:username/activate', to: 'admin#activate'
      post 'admin/users/:username/reset_password', to: 'admin#reset_password'
      
      get 'admin/announcements', to: 'admin#announcements'
      post 'admin/announcements', to: 'admin#new_announcement'
      
      post 'admin/schedule', to: 'admin#upload_schedule'
    end
  end

end
