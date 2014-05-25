Pod::Spec.new do |s|

  s.name         = "NDOverlayViewController"
  s.version      = "0.1"
  s.summary      = "A custom UIViewController container to overlay one view controller on top of another, with animation and gesture support."
  s.homepage     = "https://github.com/neildavis/NDOverlayViewController"
  s.license      = "MIT"
  s.author    = "Neil Davis"
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/neildavis/NDOverlayViewController.git", :tag => "v0.1" }
  s.source_files  = "src/**/*.{h,m}"
  s.requires_arc = true
end
