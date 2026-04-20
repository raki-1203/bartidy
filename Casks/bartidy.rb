cask "bartidy" do
  version "1.4.2"
  sha256 "93e459a18470a8decf8c1de9da70ff062ac549fbc0ad8e53d121bf7d2d00ae6f"

  url "https://github.com/raki-1203/bartidy/releases/download/v#{version}/Bartidy-#{version}.dmg"
  name "Bartidy"
  desc "Lightweight macOS menubar organizer"
  homepage "https://github.com/raki-1203/bartidy"

  depends_on macos: ">= :ventura"

  app "Bartidy.app"

  zap trash: [
    "~/Library/Preferences/com.raki1203.Bartidy.plist",
    "~/Library/Application Support/Bartidy",
    "~/Library/Caches/Bartidy",
  ]
end
