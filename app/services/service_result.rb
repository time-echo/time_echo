# frozen_string_literal: true

class ServiceResult
  attr_reader :value, :error, :code, :message, :details, :errors, :metadata

  def self.success(value = nil, **kwargs)
    new(success: true, value: value, **kwargs)
  end

  def self.failure(error = nil, message: nil, details: nil, code: nil, errors: nil, **kwargs)
    new(
      success: false,
      error: error,
      message: message,
      details: details,
      code: code,
      errors: errors,
      **kwargs
    )
  end

  def initialize(success:, value: nil, error: nil, code: nil, message: nil, details: nil, errors: nil, **extra)
    @success = !!success
    @value = value
    @error = error
    @code = code
    @message = message
    @details = details
    @errors = errors
    @metadata = extra

    extra.each do |k, v|
      singleton_class.define_method(k) { v } unless respond_to?(k)
    end
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def [](key)
    if respond_to?(key)
      public_send(key)
    elsif @value.is_a?(Hash)
      @value[key] || @value[key.to_s]
    else
      @metadata[key]
    end
  end

  def letter
    @metadata[:letter] || (@value if @value.is_a?(Letter))
  end

  def form
    @metadata[:form]
  end

  def countdown?
    !!@metadata[:countdown]
  end

  def new_email
    @metadata[:new_email] || (@value.is_a?(Hash) && (@value[:email] || @value["email"]))
  end
end
