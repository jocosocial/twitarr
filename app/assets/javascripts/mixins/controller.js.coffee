Twitarr.ControllerMixin = Ember.Mixin.create
  application: Ember.inject.controller()
  read_only: (->
    @get('application.read_only')?
  ).property('application.read_only')
  logged_in: (->
    @get('application.login_user')?
  ).property('application.login_user')
  login_user: (->
    @get('application.login_user')
  ).property('application.login_user')
  login_role: (->
    @get('application.login_role')
  ).property('application.login_role')
  role_admin: (->
    @get('application.login_role') == 'admin'
  ).property('application.login_role')
  role_tho: (->
    @get('role_admin') || @get('application.login_role') == 'tho'
  ).property('application.login_role')
  role_moderator: (->
    @get('role_tho') || @get('application.login_role') == 'moderator'
  ).property('application.login_role')
  role_muted: (->
    @get('application.login_role') == 'muted'
  ).property('application.login_role')
