// halo/middleware/secure_headers.mbt
// Security headers middleware

/// Security headers options
pub struct SecureHeadersOptions {
  x_frame_options : String
  x_content_type_options : String
  x_xss_protection : String
  strict_transport_security : String
  content_security_policy : Option[String]
}

/// Default security headers options
fn default_secure_headers_options() -> SecureHeadersOptions {
  {
    x_frame_options: "DENY",
    x_content_type_options: "nosniff",
    x_xss_protection: "1; mode=block",
    strict_transport_security: "max-age=31536000; includeSubDomains",
    content_security_policy: None,
  }
}

/// Secure headers middleware - adds security-related HTTP headers
///
/// Example:
/// ```moonbit
/// app.add_middleware(@middleware.secure_headers())
/// ```
pub fn secure_headers() -> @halo.Middleware {
  secure_headers_with_options(default_secure_headers_options())
}

/// Secure headers middleware with custom options
pub fn secure_headers_with_options(options : SecureHeadersOptions) -> @halo.Middleware {
  fn(ctx : @halo.Context, next : @halo.Next) {
    let headers = ctx.res.val.headers.val

    // X-Frame-Options - prevents clickjacking
    headers["X-Frame-Options"] = options.x_frame_options

    // X-Content-Type-Options - prevents MIME type sniffing
    headers["X-Content-Type-Options"] = options.x_content_type_options

    // X-XSS-Protection - enables XSS filter
    headers["X-XSS-Protection"] = options.x_xss_protection

    // Strict-Transport-Security - forces HTTPS
    headers["Strict-Transport-Security"] = options.strict_transport_security

    // Content-Security-Policy - optional CSP
    match options.content_security_policy {
      Some(csp) => { headers["Content-Security-Policy"] = csp }
      None => { ignore(0) }
    }

    next()
  }
}
