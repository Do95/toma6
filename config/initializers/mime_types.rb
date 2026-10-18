Mime::Type.register "application/pdf", :pdf unless Mime::Type.lookup_by_extension(:pdf)
Mime::Type.register "image/svg+xml", :svg unless Mime::Type.lookup_by_extension(:svg)
