Rails.application.routes.draw do
  get 'jobs/util'
  get 'jobs/updateprices'
  get 'jobs/pullcamdentest'
  get 'jobs/parselistings_camdentest'
  get 'jobs/updatefloorplans_camdentest'

  get 'charts/prices'

  get 'charts/util'
end
