# Use CanoKey to sign in to your Mac

Console configures two PIV slots for macOS smart-card login. Slot **9A** authenticates you when you sign in. Slot **9D** unlocks the login keychain.

1. Connect your CanoKey and open **PIV > macOS login** in Console.
2. Enter your PIV PIN and choose how to authenticate with the management key. Console checks both slots and shows what it will keep, create, or replace.
3. Review any listed replacements before selecting **Configure CanoKey**. Replacing a private key can break apps or accounts that rely on it. Console keeps existing keys and certificates that are compatible.
4. Reconnect CanoKey and follow the macOS prompt to pair it with your account. Sign out and sign in with CanoKey to verify login and keychain access.

If configuration stops partway through, reconnect the key and run the check again. Console can reuse slots it has already configured. If the Mac still does not offer pairing, check whether `sc_auth identities` lists the key and confirm that your Mac allows smart-card pairing. Pairing and certificate trust are managed by macOS.
