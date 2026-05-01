// halo/middleware/compression.mbt
// Response compression middleware (gzip / brotli)

///|
/// Compression algorithm
pub enum CompressionAlgorithm {
  Gzip
  Brotli
  Deflate
}

///|
/// Compression options
pub struct CompressionOptions {
  /// Enable gzip (default: true)
  gzip : Bool
  /// Enable brotli (default: false - requires brotli library)
  brotli : Bool
  /// Enable deflate (default: false)
  deflate : Bool
  /// Minimum size in bytes to compress (default: 1024)
  min_size : Int
  /// Compression level 1-9 (default: 6)
  level : Int
  /// Content types to compress (default: common text types)
  content_types : Array[String]
}

///|
/// Default compression options
fn default_compression_options() -> CompressionOptions {
  {
    gzip: true,
    brotli: false,
    deflate: false,
    min_size: 1024,
    level: 6,
    content_types: [
      "text/html", "text/css", "text/plain", "text/xml", "application/json", "application/javascript",
      "application/xml", "image/svg+xml",
    ],
  }
}

///|
/// Create compression middleware with default options
///
/// Example:
/// ```moonbit nocheck
/// app.use(@middleware.compression())
/// ```
pub fn compression() -> @halo.Middleware {
  compression_with_options(default_compression_options())
}

///|
/// Create compression middleware with custom options
///
/// Example:
/// ```moonbit nocheck
/// app.use(@middleware.compression_with_options({
///   gzip: true,
///   brotli: false,
///   min_size: 512,
///   level: 9,
/// }))
/// ```
pub fn compression_with_options(
  options : CompressionOptions,
) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    // Check if client accepts encoding
    let accept_encoding = ctx.get_header("Accept-Encoding")

    match accept_encoding {
      Some(encoding) => {
        // Determine best encoding to use
        let selected = select_encoding(encoding, options)

        match selected {
          Some(algo) => {
            // Wrap response to compress on the fly
            // For now, we set the header and let the body be compressed after next()
            // In production, this would use a streaming compression wrapper

            // Set Vary header
            let current_vary = ctx.res.val.headers.val.get("Vary")
            match current_vary {
              Some(v) =>
                ctx.res.val.headers.val["Vary"] = v + ", Accept-Encoding"
              None => ctx.res.val.headers.val["Vary"] = "Accept-Encoding"
            }

            // Continue the chain
            next()

            // After next(), compress the response body if applicable
            compress_response(ctx, algo, options)
          }
          None =>
            // No supported encoding, continue normally
            next()
        }
      }
      None =>
        // Client doesn't specify Accept-Encoding, continue normally
        next()
    }
  }
}

///|
/// Select best encoding based on Accept-Encoding header
fn select_encoding(
  accept_encoding : String,
  options : CompressionOptions,
) -> CompressionAlgorithm? {
  // Check for brotli first (usually best compression)
  // Look for "br" in the header (case-insensitive check by looking for both cases)
  if options.brotli &&
    (
      String::contains(accept_encoding, "br") ||
      String::contains(accept_encoding, "BR")
    ) {
    Some(Brotli)
    // Then gzip (most widely supported)
  } else if options.gzip &&
    (
      String::contains(accept_encoding, "gzip") ||
      String::contains(accept_encoding, "GZIP")
    ) {
    Some(Gzip)
    // Then deflate
  } else if options.deflate &&
    (
      String::contains(accept_encoding, "deflate") ||
      String::contains(accept_encoding, "DEFLATE")
    ) {
    Some(Deflate)
  } else {
    None
  }
}

///|
/// Check if content type should be compressed
fn should_compress_type(
  content_type : String,
  options : CompressionOptions,
) -> Bool {
  // Check if content type is in the list
  for ct in options.content_types {
    if String::has_prefix(content_type, ct) {
      return true
    }
  }
  false
}

///|
/// Compress response body if conditions are met
fn compress_response(
  ctx : @halo.Context,
  algo : CompressionAlgorithm,
  options : CompressionOptions,
) -> Unit {
  let body = ctx.res.val.body.val
  let content_type = ctx.res.val.headers.val.get("Content-Type")

  match body {
    Some(body_str) => {
      // Check minimum size
      if String::length(body_str) < options.min_size {
        return
      }

      // Check content type
      match content_type {
        Some(ct) => if !should_compress_type(ct, options) { return }
        None => return
      }

      // Compress based on algorithm
      match algo {
        Gzip =>
          match compress_gzip(body_str, options.level) {
            Some(compressed) => {
              ctx.res.val.body.val = Some(compressed)
              ctx.res.val.headers.val["Content-Encoding"] = "gzip"
              let len_header = Int::to_string(String::length(compressed))
              ctx.res.val.headers.val["Content-Length"] = len_header
            }
            None => ()
          }
        Brotli =>
          match compress_brotli(body_str, options.level) {
            Some(compressed) => {
              ctx.res.val.body.val = Some(compressed)
              ctx.res.val.headers.val["Content-Encoding"] = "br"
              let len_header = Int::to_string(String::length(compressed))
              ctx.res.val.headers.val["Content-Length"] = len_header
            }
            None => ()
          }
        Deflate =>
          match compress_deflate(body_str, options.level) {
            Some(compressed) => {
              ctx.res.val.body.val = Some(compressed)
              ctx.res.val.headers.val["Content-Encoding"] = "deflate"
              let len_header = Int::to_string(String::length(compressed))
              ctx.res.val.headers.val["Content-Length"] = len_header
            }
            None => ()
          }
      }
    }
    None => ()
  }
}

///|
/// Compress with gzip (placeholder - requires MoonBit gzip support)
///
/// Note: This is a placeholder. Actual implementation requires
/// MoonBit runtime or library support for gzip compression.
fn compress_gzip(_data : String, _level : Int) -> String? {
  // Placeholder: In production, use MoonBit's gzip library
  // For now, return None to indicate compression not available
  //
  // Expected API when available:
  // ```moonbit
  // Compression::gzip(data, level)
  // ```
  None
}

///|
/// Compress with brotli (placeholder - requires brotli library)
fn compress_brotli(_data : String, _level : Int) -> String? {
  // Placeholder: In production, use brotli library
  None
}

///|
/// Compress with deflate (placeholder - requires zlib or similar)
fn compress_deflate(_data : String, _level : Int) -> String? {
  // Placeholder: In production, use zlib or similar
  None
}

///|
/// Get compression statistics for monitoring
pub struct CompressionStats {
  /// Total requests processed
  total_requests : Ref[Int]
  /// Compressed responses
  compressed_count : Ref[Int]
  /// Total bytes before compression
  original_bytes : Ref[Int]
  /// Total bytes after compression
  compressed_bytes : Ref[Int]
}

///|
/// Global compression stats
let compression_stats : CompressionStats = {
  total_requests: { val: 0 },
  compressed_count: { val: 0 },
  original_bytes: { val: 0 },
  compressed_bytes: { val: 0 },
}

///|
/// Get current compression stats
pub fn get_compression_stats() -> CompressionStats {
  compression_stats
}

///|
/// Reset compression stats
pub fn reset_compression_stats() -> Unit {
  compression_stats.total_requests.val = 0
  compression_stats.compressed_count.val = 0
  compression_stats.original_bytes.val = 0
  compression_stats.compressed_bytes.val = 0
}

///|
/// Get compression ratio as percentage
pub fn get_compression_ratio() -> Float {
  let original = compression_stats.original_bytes.val
  let compressed = compression_stats.compressed_bytes.val

  if original > 0 {
    Float::from_int(100 - compressed * 100 / original)
  } else {
    0.0
  }
}

///|
/// Helper to create compression options for testing
pub fn make_compression_options(
  gzip : Bool,
  brotli : Bool,
  deflate : Bool,
  min_size : Int,
  level : Int,
  content_types : Array[String],
) -> CompressionOptions {
  { gzip, brotli, deflate, min_size, level, content_types }
}
