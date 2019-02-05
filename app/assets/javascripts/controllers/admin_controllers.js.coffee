Twitarr.AdminUsersController = Twitarr.ArrayController.extend()

Twitarr.AdminProfileController = Twitarr.ObjectController.extend
  changed: false
  errors: Ember.A()

  is_active: (->
    @get('status') is 'active'
  ).property('status')

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
