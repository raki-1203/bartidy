cask "bartidy" do
  version "1.4.14"
  sha256 "f017fa699b71a69c222d2f450a7007f491b109484417f493ef96f600fd5751bc"

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
