Rails.application.routes.draw do
  get 'jobs/util'
  get 'jobs/updateprices'
  get 'jobs/pullcamdentest'
  get 'jobs/parselistingstest'
  get 'jobs/updatefloorplanstest'

  get 'charts/util'
end
