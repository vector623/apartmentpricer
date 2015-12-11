require 'pry'
class JobsController < ApplicationController
  def util
    binding.pry
  end
end
