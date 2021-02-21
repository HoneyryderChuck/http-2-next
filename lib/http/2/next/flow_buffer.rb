# frozen_string_literal: true

module HTTP2Next
  # Implementation of stream and connection DATA flow control: frames may
  # be split and / or may be buffered based on current flow control window.
  #
  module FlowBuffer
    include Error

    MAX_WINDOW_SIZE = 2**31 - 1

    # Amount of buffered data. Only DATA payloads are subject to flow stream
    # and connection flow control.
    #
    # @return [Integer]
    def buffered_amount
      send_buffer.bytesize
    end

    def flush
      send_data
    end

    private

    def send_buffer
      @send_buffer ||= FrameBuffer.new
    end

    def update_local_window(frame)
      frame_size = frame[:payload].bytesize
      frame_size += frame[:padding] || 0
      @local_window -= frame_size
    end

    def calculate_window_update(window_max_size)
      # If DATA frame is received with length > 0 and
      # current received window size + delta length is strictly larger than
      # local window size, it throws a flow control error.
      #
      error(:flow_control_error) if @local_window < 0

      # Send WINDOW_UPDATE if the received window size goes over
      # the local window size / 2.
      #
      # The HTTP/2 spec mandates that every DATA frame received
      # generates a WINDOW_UPDATE to send. In some cases however,
      # (ex: DATA frames with short payloads),
      # the noise generated by flow control frames creates enough
      # congestion for this to be deemed very inefficient.
      #
      # This heuristic was inherited from nghttp, which delays the
      # WINDOW_UPDATE until at least half the window is exhausted.
      # This works because the sender doesn't need those increments
      # until the receiver window is exhausted, after which he'll be
      # waiting for the WINDOW_UPDATE frame.
      return unless @local_window <= (window_max_size / 2)

      window_update(window_max_size - @local_window)
    end

    # Buffers outgoing DATA frames and applies flow control logic to split
    # and emit DATA frames based on current flow control window. If the
    # window is large enough, the data is sent immediately. Otherwise, the
    # data is buffered until the flow control window is updated.
    #
    # Buffered DATA frames are emitted in FIFO order.
    #
    # @param frame [Hash]
    # @param encode [Boolean] set to true by connection
    def send_data(frame = nil, encode = false)
      send_buffer << frame unless frame.nil?

      while (frame = send_buffer.retrieve(@remote_window))

        # puts "#{self.class} -> #{@remote_window}"
        sent = frame[:payload].bytesize

        manage_state(frame) do
          if encode
            encode(frame).each { |f| emit(:frame, f) }
          else
            emit(:frame, frame)
          end
          @remote_window -= sent
        end
      end
    end

    def process_window_update(frame:, encode: false)
      return if frame[:ignore]

      if frame[:increment]
        raise ProtocolError, "increment MUST be higher than zero" if frame[:increment].zero?

        @remote_window += frame[:increment]
        error(:flow_control_error, msg: "window size too large") if @remote_window > MAX_WINDOW_SIZE
      end
      send_data(nil, encode)
    end
  end

  class FrameBuffer
    attr_reader :bytesize

    def initialize
      @buffer = []
      @bytesize = 0
    end

    def <<(frame)
      @buffer << frame
      @bytesize += frame[:payload].bytesize
    end

    def empty?
      @bytesize == 0
    end

    def retrieve(window_size)
      return if @buffer.empty?

      frame = @buffer.first

      frame_size = frame[:payload].bytesize
      end_stream = frame[:flags].include? :end_stream

      # Frames with zero length with the END_STREAM flag set (that
      # is, an empty DATA frame) MAY be sent if there is no available space
      # in either flow control window.
      return if window_size <= 0 && !(frame_size == 0 && end_stream)

      @buffer.shift

      if frame_size > window_size
        payload = frame.delete(:payload)
        chunk   = frame.dup

        # Split frame so that it fits in the window
        # TODO: consider padding!
        frame_bytes = payload.byteslice(0, window_size)
        payload = payload.byteslice(window_size..-1)

        frame[:payload] = frame_bytes
        frame[:length] = frame_bytes.bytesize
        chunk[:payload] = payload
        chunk[:length]  = payload.bytesize

        # if no longer last frame in sequence...
        frame[:flags] -= [:end_stream] if end_stream

        @buffer.unshift(chunk)
        @bytesize -= window_size
      else
        @bytesize -= frame_size
      end
      frame
    end
  end
end
