# frozen_string_literal: true

Rails.application.routes.draw do
  root 'application#index'

  namespace :api do
    namespace :v2 do
      resources :event, only: [:index, :destroy]
      get 'event/:id', to: 'event#show'
      post 'event/:id', to: 'event#update'
      get 'event/:id/ical', to: 'event#ical'
      post 'event/:id/favorite', to: 'event#follow'
      delete 'event/:id/favorite', to: 'event#unfollow'
      get 'event/mine/:day', to: 'event#mine'
      get 'event/mine_soon/:minutes', to: 'event#mine_soon'
      get 'event/day/:day', to: 'event#day'

      get 'forums', to: 'forums#index'
      post 'forums', to: 'forums#create'
      get 'forums/:id', to: 'forums#show'
      post 'forums/:id', to: 'forums#new_post'
      delete 'forums/:id', to: 'forums#delete'
      get 'forums/:id/:post_id', to: 'forums#load_post'
      post 'forums/:id/:post_id', to: 'forums#update_post'
      delete 'forums/:id/:post_id', to: 'forums#delete_post'
      post 'forums/:id/:post_id/react/:type', to: 'forums#react'
      delete 'forums/:id/:post_id/react/:type', to: 'forums#unreact'
      get 'forums/:id/:post_id/react', to: 'forums#show_reacts'
      post 'forum/:id/sticky/:sticky', to: 'forums#sticky'
      post 'forum/:id/locked/:locked', to: 'forums#locked'
      post 'forum/mark_all_read', to: 'forums#mark_all_read'

      resources :stream, only: [:new, :create]
      get 'stream', to: 'stream#index'
      get 'stream/:start', to: 'stream#index'
      get 'stream/m/:query', to: 'stream#view_mention', query: /.*/
      get 'stream/h/:query', to: 'stream#view_hash_tag', query: /.*/

      get 'thread/:id', to: 'stream#show'
      get 'tweet/:id', to: 'stream#get'
      post 'tweet/:id', to: 'stream#update'
      delete 'tweet/:id', to: 'stream#delete'
      get 'tweet/:id/react', to: 'stream#show_reacts'
      post 'tweet/:id/react/:type', to: 'stream#react'
      delete 'tweet/:id/react/:type', to: 'stream#unreact'
      post 'tweet/:id/locked/:locked', to: 'stream#locked'

      post 'user/new', to: 'user#new'
      get 'user/new_seamail', to: 'user#new_seamail'
      get 'user/mentions', to: 'user#mentions'
      get 'user/auth', to: 'user#auth'
      post 'user/auth', to: 'user#auth'
      post 'user/reset_password', to: 'user#reset_password'
      get 'user/logout', to: 'user#logout'
      post 'user/logout', to: 'user#logout'
      get 'user/whoami', to: 'user#whoami'
      get 'user/profile', to: 'user#whoami'
      post 'user/profile', to: 'user#update_profile'
      post 'user/change_password', to: 'user#change_password'
      get 'user/profile/:username', to: 'user#show'
      post 'user/profile/:username/star', to: 'user#star'
      post 'user/profile/:username/personal_comment', to: 'user#personal_comment'
      get 'user/ac/:query', to: 'user#auto_complete', query: /.*/
      get 'user/starred', to: 'user#starred'
      get 'user/photo/:username', to: 'user#photo'
      post 'user/photo', to: 'user#update_photo'
      delete 'user/photo', to: 'user#reset_photo'
      post 'user/schedule', to: 'user#upload_schedule'

      get 'hashtag/repopulate', to: 'hashtag#populate_hashtags'
      get 'hashtag/ac/:query', to: 'hashtag#auto_complete', query: /.*/

      get 'search/all/:query', to: 'search#all', query: /.*/
      get 'search/users/:query', to: 'search#users', query: /.*/
      get 'search/seamails/:query', to: 'search#seamails', query: /.*/
      get 'search/tweets/:query', to: 'search#tweets', query: /.*/
      get 'search/forums/:query', to: 'search#forums', query: /.*/
      get 'search/events/:query', to: 'search#events', query: /.*/

      get 'alerts', to: 'alerts#index'
      get 'alerts/check', to: 'alerts#check'
      post 'alerts/last_checked', to: 'alerts#last_checked'

      resources :seamail, except: [:destroy, :edit, :new], defaults: { format: 'json' }
      get 'seamail_threads', to: 'seamail#threads'
      post 'seamail/:id/', to: 'seamail#new_message'
      # post 'seamail/:id/recipients', to: 'seamail#recipients'

      get 'text/:filename', to: 'text#index'
      get 'time', to: 'text#time'
      get 'reactions', to: 'text#reactions'
      get 'announcements', to: 'text#announcements'

      resources :photo, only: [:index, :create, :destroy, :show], defaults: { format: 'json' }
      get 'photo/small_thumb/:id', to: 'photo#small_thumb'
      get 'photo/medium_thumb/:id', to: 'photo#medium_thumb'
      get 'photo/full/:id', to: 'photo#full'

      get 'admin/users', to: 'admin#users'
      get 'admin/users/:query', to: 'admin#user', query: /.*/
      get 'admin/user/:username/profile', to: 'admin#profile'
      post 'admin/user/:username', to: 'admin#update_user'
      # post 'admin/user/:username/activate', to: 'admin#activate'
      post 'admin/user/:username/reset_password', to: 'admin#reset_password'
      post 'admin/user/:username/reset_photo', to: 'admin#reset_photo'
      get 'admin/user/:username/regcode', to: 'admin#regcode'
      get 'admin/clear_text_cache', to: 'admin#clear_text_cache'

      get 'admin/announcements', to: 'admin#announcements'
      post 'admin/announcements', to: 'admin#new_announcement'
      get 'admin/announcements/:id', to: 'admin#announcement'
      post 'admin/announcements/:id', to: 'admin#update_announcement'
      delete 'admin/announcements/:id', to: 'admin#delete_announcement'

      post 'admin/schedule', to: 'admin#upload_schedule'

      get 'admin/sections', to: 'admin#sections'
      post 'admin/sections/:name', to: 'admin#section_toggle'
    end
  end
  get '*unmatched_route', to: 'application#route_not_found'
end
