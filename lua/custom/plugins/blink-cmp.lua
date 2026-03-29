-- Use the Rust fuzzy binary for better performance.
-- blink.cmp will download a prebuilt binary on :Lazy build blink.cmp
return {
  'saghen/blink.cmp',
  opts = {
    fuzzy = { implementation = 'prefer_rust_with_warning', prebuilt_binaries = { download = true } },
  },
}
