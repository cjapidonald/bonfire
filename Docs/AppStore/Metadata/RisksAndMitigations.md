# Risks and Mitigations

- **Hit-testing accuracy**
  - **Risk:** Complex gesture surfaces on smaller devices may register the wrong targets, causing interaction frustration and QA rejections.
  - **Mitigation:** Instrument automated hit-testing sweeps and manual device spot checks to verify tap tolerance before every submission.
- **Performance degradation strategy**
  - **Risk:** Intensive particle effects and physics spikes can drop frame rates below App Review thresholds.
  - **Mitigation:** Ship a degradable graphics profile with runtime fallbacks that throttle effect density under sustained load.
- **Audio privacy policy**
  - **Risk:** Optional narration capture might be perceived as storing or transmitting user audio without consent.
  - **Mitigation:** Keep recording data on-device, document retention limits in the privacy policy, and require explicit opt-in before capture begins.
- **Anti-cheating validation**
  - **Risk:** Players could tamper with local state to fabricate competitive progress or unlocks.
  - **Mitigation:** Validate achievements on a server-side authority that cross-checks telemetry for anomalies before accepting updates.
- **Localization architecture**
  - **Risk:** Divergent string sources across features risk regressions between English and Vietnamese builds.
  - **Mitigation:** Centralize translations in shared string tables, enforce locale coverage in CI, and block releases on missing keys.
