cask "bartidy" do
  version "1.3.0"
  sha256 "c583a4f091dfec606ed8b67b50dd7f9759035959a17c6557421ce8454b65057a"

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
