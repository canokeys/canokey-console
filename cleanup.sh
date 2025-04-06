IPA_PATH="build/ios/ipa/CanoKey Console.ipa"

if [ -f "$IPA_PATH" ]; then
  echo "Checking for unwanted files like ._Symbols in $IPA_PATH"
  unzip -l "$IPA_PATH" | grep ._Symbols && zip -d "$IPA_PATH" ._Symbols/ || echo "No ._Symbols found"
else
  echo "IPA not found at $IPA_PATH"
fi
