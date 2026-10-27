# frozen_string_literal: true

require "pagy"

Pagy::DEFAULT[:limit] = 20
Pagy::DEFAULT[:page_param] = :page
