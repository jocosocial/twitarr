Twitarr.ControllerMixin = Ember.Mixin.create
  needs: 'application'
  read_only: (->
    @get('controllers.application.read_only')?
  ).property('controllers.application.read_only')
  logged_in: (->
    @get('controllers.application.login_user')?
  ).property('controllers.application.login_user')
  login_user: (->
    @get('controllers.application.login_user')
  ).property('controllers.application.login_user')
  login_admin: (->
    @get('controllers.application.login_admin')
  ).property('controllers.application.login_admin')