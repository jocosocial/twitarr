Twitarr.AdminUsersController = Twitarr.ArrayController.extend()

Twitarr.AdminProfileController = Twitarr.ObjectController.extend
  errors: Ember.A()
  roles: [
    {label: "Admin", value: "admin"},
    {label: "THO", value: "tho"},
    {label: "Moderator", value: "moderator"},
    {label: "User", value: "user"},
    {label: "Muted", value: "muted"},
    {label: "Banned", value: "banned"}
  ]

  is_banned: (->
    @get('role') is 'banned'
  ).property('role')

  is_muted: (->
    @get('role') is 'muted'
  ).property('role')

Twitarr.AdminAnnouncementsController = Twitarr.Controller.extend()

Twitarr.AdminUploadScheduleController = Twitarr.Controller.extend
  schedule_upload_url: (->
    "#{Twitarr.api_path}/admin/schedule"
  ).property()

  actions:
    file_uploaded: (data) ->
      alert data.status unless data.status is 'ok'
    start_upload: ->
      @get('controllers.application').send('start_upload')
    end_upload: ->
      @get('controllers.application').send('end_upload')
