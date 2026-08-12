# Performance tuning

## Measure the correct thing

Internet speed tests measure throughput to a test server. They do not prove low
LAN jitter, low Wi-Fi contention, or a short encode/decode queue. Use Moonlight's
stream statistics and separate:

- network latency and variance;
- host processing/encoding latency;
- client decoding latency;
- rendering delay and dropped frames.

## Host

- Connect the Mac by Ethernet.
- Use `encoder = videotoolbox` and `vt_realtime = 1`.
- Keep the physical display at the same refresh family as the stream when
  possible: 60/120 Hz for 60/120 FPS.
- Leave `max_bitrate = 0` if the client should choose the bitrate.
- Keep `fec_percentage` low on a clean LAN; 5 is the tested starting point.
- Avoid running a virtual display when the goal is the current desktop.

## Client

- Prefer 5/6 GHz Wi-Fi with a clean channel and strong signal.
- Start at 60 FPS and validate zero packet loss before selecting 90/120 FPS.
- H.264 generally has the shortest encode/decode path; HEVC provides better
  quality per bit and was validated with VideoToolbox in this build.
- Do not raise bitrate until packet loss or frame-queue growth appears. A lower,
  stable bitrate often feels smoother than an uncapped peak.

## 90/120 FPS

The client request does not create frames the game or physical display cannot
produce. For 120 FPS, verify all four links:

1. the game sustains close to 120 FPS;
2. the Mac display runs at 120 Hz;
3. Sunshine reports the intended session frame rate;
4. the iPhone model and Moonlight decode/render at 120 Hz.

## Codec expectations

The tested Apple Silicon build advertises hardware H.264 and HEVC. AV1 probing may
fail on hardware without a VideoToolbox AV1 encoder; that startup probe error is
not a streaming failure. Do not force AV1 unless the log confirms it is available.
