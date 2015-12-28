Rails.application.routes.draw do
  get 'jobs/util'
  get 'jobs/updateprices'
  get 'jobs/pullpages_test'
  get 'jobs/parselistings_camdentest'
  get 'jobs/updatefloorplans_camdentest'

  get 'charts/prices'
  get 'charts/unit'
  get 'charts/util'
end
