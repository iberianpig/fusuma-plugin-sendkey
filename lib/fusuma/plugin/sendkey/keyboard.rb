# frozen_string_literal: true

require_relative './device.rb'

# Emulate Keyboard
class Keyboard
  def initialize(device: nil)
    @device = device || Device.new
  end

  # @param param [String]
  def type_command(param:)
    return unless param.is_a?(String)

    codes = param.split('+')
    press_commands = codes.map { |code| press_command(code) }
    release_commands = codes.reverse.map { |code| release_command(code) }

    (press_commands | release_commands).join(' && ')
  end

  def press_command(code)
    return unless support?(code)

    @device.emulate(code: code, press: true)
  end

  def release_command(code)
    return unless support?(code)

    @device.emulate(code: code, press: false)
  end

  def support?(code)
    @supported_code ||= {}
    @supported_code[code] ||= if @device.support?(code)
                                true
                              else
                                warn "sendkey: #{code} is unsupported."
                                warn 'Please check your config.yml.'
                                exit 1
                              end
  end

  def available_codes
    @device.search_codes
  end
end
