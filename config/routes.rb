Twitarr::Application.routes.draw do
  root 'application#index'

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
      get 'tweet/:id/react', to: 'stream#show_reacts'
      post 'tweet/:id/react/:type', to: 'stream#react'
      delete 'tweet/:id/react/:type', to: 'stream#unreact'

      post 'user/new', to: 'user#new'
      get 'user/new_seamail', to: 'user#new_seamail'
      delete 'user/mentions', to:'user#reset_mentions'
      get 'user/mentions', to:'user#mentions'
      get 'user/auth', to: 'user#auth'
      post 'user/auth', to: 'user#auth'
      post 'user/reset_password', to: 'user#reset_password'
      get 'user/logout', to: 'user#logout'
      post 'user/logout', to: 'user#logout'
      get 'user/whoami', to: 'user#whoami'
      get 'user/profile', to: 'user#whoami'
      post 'user/profile', to: 'user#update_profile'
      get 'user/profile/:username', to: 'user#show'
      get 'user/profile/:username/star', to: 'user#star'
      post 'user/profile/:username/personal_comment', to: 'user#personal_comment'
      get 'user/ac/:query', to: 'user#auto_complete'
      get 'user/view/:username', to: 'user#show'
      get 'user/starred', to: 'user#starred'
      get 'user/photo/:username', to: 'user#get_photo'
      post 'user/photo', to: 'user#update_photo'
      delete 'user/photo', to: 'user#reset_photo'

      get 'hashtag/repopulate', to: 'hashtag#populate_hashtags'
      get 'hashtag/ac/:query', to: 'hashtag#auto_complete'

      get 'search/all/:query', to: 'search#all'
      get 'search/users/:query', to: 'search#users'
      get 'search/seamails/:query', to: 'search#seamails'
      get 'search/tweets/:query', to: 'search#tweets'
      get 'search/forums/:query', to: 'search#forums'
      get 'search/events/:query', to: 'search#events'

      get 'alerts', to: 'alerts#index'
      get 'alerts/check', to: 'alerts#check'

      resources :seamail, except: [:destroy, :edit, :new], :defaults => { :format => 'json' }
      get 'seamail_threads', to: 'seamail#threads'
      post 'seamail/:id/', to: 'seamail#new_message'
      # post 'seamail/:id/recipients', to: 'seamail#recipients'

      get 'text/:filename', to: 'text#index'
      get 'time', to: 'text#time'
      get 'reactions', to: 'text#reactions'
      get 'announcements', to: 'text#announcements'

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
