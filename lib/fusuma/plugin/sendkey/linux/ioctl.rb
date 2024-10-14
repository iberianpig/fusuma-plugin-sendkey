# frozen_string_literal: true

module Fusuma
  module Plugin
    module Sendkey
      module Linux
        # https://github.com/jtzero/vigilem-evdev/blob/master/lib/vigilem/evdev/system/ioctl.rb?plain=1#L16
        module IOCTRL
          # @return [Integer] 8
          def _IOC_NRBITS
            8
          end

          # @return [Integer] 8
          def _IOC_TYPEBITS
            8
          end

          # @return [Integer] 14
          def _IOC_SIZEBITS
            14
          end

          # @return [Integer] 2
          def _IOC_DIRBITS
            2
          end

          # @return [Integer]
          def _IOC_NRMASK
            ((1 << _IOC_NRBITS) - 1)
          end

          # @return [Integer]
          def _IOC_TYPEMASK
            ((1 << _IOC_TYPEBITS) - 1)
          end

          # @return [Integer]
          def _IOC_SIZEMASK
            ((1 << _IOC_SIZEBITS) - 1)
          end

          # @return [Integer]
          def _IOC_DIRMASK
            ((1 << _IOC_DIRBITS) - 1)
          end

          # @return [Integer]
          def _IOC_NRSHIFT
            0
          end

          # @return [Integer]
          def _IOC_TYPESHIFT
            (_IOC_NRSHIFT + _IOC_NRBITS)
          end

          # @return [Integer]
          def _IOC_SIZESHIFT
            (_IOC_TYPESHIFT + _IOC_TYPEBITS)
          end

          # @return [Integer]
          def _IOC_DIRSHIFT
            (_IOC_SIZESHIFT + _IOC_SIZEBITS)
          end

          def IOC_IN
            (_IOC_WRITE << _IOC_DIRSHIFT)
          end

          def IOC_OUT
            (_IOC_READ << _IOC_DIRSHIFT)
          end

          def IOC_INOUT
            ((_IOC_WRITE | _IOC_READ) << _IOC_DIRSHIFT)
          end

          # @return [Integer]
          def IOCSIZE_MASK
            (_IOC_SIZEMASK << _IOC_SIZESHIFT)
          end

          # @return [Integer]
          def IOCSIZE_SHIFT
            _IOC_SIZESHIFT
          end

          # direction bits

          # no data transfer
          # @return [Integer] 0
          def _IOC_NONE
            0
          end

          # @return [Integer] 1
          def _IOC_WRITE
            1
          end

          # @return [Integer] 2
          def _IOC_READ
            2
          end

          #
          # @param  [Integer] dir The direction of data transfer
          # @option dir [Integer] _IOC_NONE
          # @option dir [Integer] _IOC_READ
          # @option dir [Integer] _IOC_WRITE
          # @option dir [Integer] _IOC_READ|_IOC_WRITE
          # @!macro type_nr_fmt_return_Integer
          def _IOC(dir, type, nr, size)
            (native_signed_long(dir << _IOC_DIRSHIFT) | (type.ord << _IOC_TYPESHIFT) |
             (nr << _IOC_NRSHIFT) | (size << _IOC_SIZESHIFT))
          end

          # https://github.com/jtzero/vigilem-support/blob/4ce72bd01980ed9049e8c03c3d1437f1d4d0de7a/lib/vigilem/support/system.rb#L59C1-L64C8
          # @param  [Numeric] number
          # @return the same number converted to a native signed long
          def native_signed_long(number)
            [number].pack("l!").unpack1("l!")
          end
        end
      end
    end
  end
end
