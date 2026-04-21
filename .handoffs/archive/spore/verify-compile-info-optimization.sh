#!/usr/bin/env bash
set -euo pipefail
handoff=".handoffs/archive/spore/compile-info-optimization.md"
pass=0
fail=0
grep -q "Status" "$handoff" && pass=$((pass+1)) || { echo "FAIL: status section missing"; fail=$((fail+1)); }
grep -q "optional Cargo features" "$handoff" && pass=$((pass+1)) || { echo "FAIL: optional feature note missing"; fail=$((fail+1)); }
grep -q "cargo build --no-default-features" "$handoff" && pass=$((pass+1)) || { echo "FAIL: slim build validation missing"; fail=$((fail+1)); }
grep -q "cargo test --no-default-features" "$handoff" && pass=$((pass+1)) || { echo "FAIL: slim test validation missing"; fail=$((fail+1)); }
grep -q 'default = \["logging", "http"\]' /Users/williamnewton/projects/basidiocarp/spore/Cargo.toml && pass=$((pass+1)) || { echo "FAIL: default feature table missing"; fail=$((fail+1)); }
grep -q 'logging = \["dep:tracing-subscriber"\]' /Users/williamnewton/projects/basidiocarp/spore/Cargo.toml && pass=$((pass+1)) || { echo "FAIL: logging feature wiring missing"; fail=$((fail+1)); }
grep -q 'http = \["dep:ureq"\]' /Users/williamnewton/projects/basidiocarp/spore/Cargo.toml && pass=$((pass+1)) || { echo "FAIL: http feature wiring missing"; fail=$((fail+1)); }
grep -q 'tracing-subscriber = { version = "0.3", default-features = false, features = \["ansi", "env-filter", "fmt", "json"\], optional = true }' /Users/williamnewton/projects/basidiocarp/spore/Cargo.toml && pass=$((pass+1)) || { echo "FAIL: tracing-subscriber feature set missing"; fail=$((fail+1)); }
grep -q 'ureq = { version = "3", default-features = false, features = \["rustls"\], optional = true }' /Users/williamnewton/projects/basidiocarp/spore/Cargo.toml && pass=$((pass+1)) || { echo "FAIL: ureq feature set missing"; fail=$((fail+1)); }
grep -q '\[profile.dev\]' /Users/williamnewton/projects/basidiocarp/spore/Cargo.toml && pass=$((pass+1)) || { echo "FAIL: dev profile missing"; fail=$((fail+1)); }
grep -q 'panic = "abort"' /Users/williamnewton/projects/basidiocarp/spore/Cargo.toml && pass=$((pass+1)) || { echo "FAIL: release panic policy missing"; fail=$((fail+1)); }
grep -q 'header("Accept-Encoding", "identity")' /Users/williamnewton/projects/basidiocarp/spore/src/self_update.rs && pass=$((pass+1)) || { echo "FAIL: identity accept-encoding missing"; fail=$((fail+1)); }
if cd spore && cargo tree --no-default-features -e features | rg -q 'tracing-subscriber|ureq'; then
  echo "FAIL: slim feature tree still includes logging/http baggage"
  fail=$((fail+1))
else
  pass=$((pass+1))
fi
echo "Results: $pass passed, $fail failed"
exit "$fail"
