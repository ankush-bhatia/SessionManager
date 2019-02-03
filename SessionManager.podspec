Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '12.0'
s.name = "SessionManager"
s.summary = "Light weight http request handling."
s.description = <<-DESC
SessionManager lets a user to create http requests to the server. It is based on URLSession framework from Apple. It handles all type of error code that can come from server while making calls to the server.
DESC
s.requires_arc = true
s.social_media_url = 'https://twitter.com/ankush1419'

# 2
s.version = "1.0.3"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Ankush Bhatia" => "ankushbhatia1347@gmail.com" }

# 5 - Replace this URL with your own GitHub page's URL (from the address bar)
s.homepage = "https://github.com/ankush-bhatia/SessionManager"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/ankush-bhatia/SessionManager.git",
:tag => "#{s.version}" }

# 7
s.framework = "UIKit"

# 8
s.source_files = "SessionManager/**/*.{swift}", "SessionManager/SessionManager/info.plist"

# 9
# s.resources = "SessionManager/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

# 10
s.swift_version = "4.2"

end
