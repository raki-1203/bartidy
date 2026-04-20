cask "bartidy" do
  version "1.4.5"
  sha256 "37efedf48b9a56a323a4c5a1759b432bbba92079694b754fe817234a847f97c0"

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
