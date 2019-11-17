# frozen_string_literal: true

require "helper"

RSpec.describe HTTP2Next::Server do
  include FrameHelpers
  let(:srv) { Server.new }
  let(:f) { Framer.new }

  context "initialization and settings" do
    it "should return even stream IDs" do
      expect(srv.new_stream.id).to be_even
    end

    it "should emit SETTINGS on new connection" do
      frames = []
      srv.on(:frame) { |recv| frames << recv }
      srv << CONNECTION_PREFACE_MAGIC

      expect(f.parse(frames[0])[:type]).to eq :settings
    end

    it "should initialize client with custom connection settings" do
      frames = []

      srv = Server.new(settings_max_concurrent_streams: 200,
                       settings_initial_window_size: 2**10)
      srv.on(:frame) { |recv| frames << recv }
      srv << CONNECTION_PREFACE_MAGIC

      frame = f.parse(frames[0])
      expect(frame[:type]).to eq :settings
      expect(frame[:payload]).to include([:settings_max_concurrent_streams, 200])
      expect(frame[:payload]).to include([:settings_initial_window_size, 2**10])
    end
  end

  it "should allow server push" do
    client = Client.new
    client.on(:frame) { |bytes| srv << bytes }

    srv.on(:stream) do |stream|
      expect do
        stream.promise(":method" => "GET") {}
      end.to_not raise_error
    end

    client.new_stream
    client.send headers_frame
  end

  context "stream management" do
    it "should initialize stream with HEADERS priority value" do
      srv << CONNECTION_PREFACE_MAGIC
      srv << f.generate(settings_frame)

      stream = nil
      headers = headers_frame
      headers[:weight] = 20
      headers[:dependency] = 0
      headers[:exclusive] = false

      srv.on(:stream) { |s| stream = s }
      srv << f.generate(headers)

      expect(stream.weight).to eq 20
    end

    it "should process connection management frames after GOAWAY" do
      srv << CONNECTION_PREFACE_MAGIC
      srv << f.generate(settings_frame)
      srv << f.generate(headers_frame)
      srv << f.generate(goaway_frame)
      srv << f.generate(headers_frame.merge(stream: 3))
      expect(srv.active_stream_count).to eq 1
    end
  end

  context "API" do
    it ".goaway should generate GOAWAY frame with last processed stream ID" do
      srv << CONNECTION_PREFACE_MAGIC
      srv << f.generate(settings_frame)
      srv << f.generate(headers_frame)

      expect(srv).to receive(:send) do |frame|
        expect(frame[:type]).to eq :goaway
        expect(frame[:last_stream]).to eq 1
        expect(frame[:error]).to eq :internal_error
        expect(frame[:payload]).to eq "payload"
      end

      srv.goaway(:internal_error, "payload")
    end
  end
end
