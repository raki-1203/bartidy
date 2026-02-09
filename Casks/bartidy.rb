cask "bartidy" do
  version "1.2.0"
  sha256 "2afacedc8652eb6301337e0a669841dd3776bdd295e14168242d16e17507cfc4"

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
