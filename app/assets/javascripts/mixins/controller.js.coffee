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
  login_role: (->
    @get('controllers.application.login_role')
  ).property('controllers.application.login_role')
  role_admin: (->
    @get('controllers.application.login_role') == 'admin'
  ).property('controllers.application.login_role')
  role_tho: (->
    @get('role_admin') || @get('controllers.application.login_role') == 'tho'
  ).property('controllers.application.login_role')
  role_moderator: (->
    @get('role_tho') || @get('controllers.application.login_role') == 'moderator'
  ).property('controllers.application.login_role')
  role_muted: (->
    @get('controllers.application.login_role') == 'muted'
  ).property('controllers.application.login_role')
