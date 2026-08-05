# Secrets

**No credentials are stored in this bundle, and the `.gitignore` at the root
actively blocks them from being added.** This was a deliberate choice, not an
oversight — here's the reasoning, then the tooling.

## Why not just copy them in

You asked for the install script to carry your AWS and GitHub logins across.
The mechanics are easy; the problem is where those files would end up.

A rice bundle is the single most-copied, most-published kind of directory a
Linux user owns. It goes on USB sticks, into `scp`, and — for most people
eventually — into a public `dotfiles` repo, because that's what you do with a
setup you're proud of. Anything sitting in it inherits that entire blast
radius, permanently, and a `git push` can't be taken back: the object stays in
the history and in every clone and fork.

What would have been in there:

| File | Contents |
|---|---|
| `~/.aws/credentials` | **Long-lived static access keys** for 4 profiles: `default`, `amplify-deploy`, `daignostics-main`, `sandi.baressi-segota` |
| `~/.ssh/` | Private keys |
| `~/.wakatime.cfg` | WakaTime API key |
| `~/.gnupg/` | GPG secret keyring |

Static IAM keys are the ones genuinely worth friction to avoid leaking: they
don't expire, aren't tied to a device, and don't prompt anyone when used from
somewhere new — so a leaked pair is usable immediately and indefinitely, by
anyone, from anywhere.

**Not** on that list: your GitHub token. `gh` on this machine stores it in the
system keyring (`gh auth status` reports `(keyring)`), so `~/.config/gh/hosts.yml`
contains only your username and git protocol — no credential. Copying that file
to a new machine transfers no access; you have to run `gh auth login` there
regardless. The `.gitignore` still blocks `hosts.yml` as a precaution, because
`gh` falls back to writing the token into it in plaintext on systems with no
keyring available.

So: dotfiles and wallpapers are in the bundle. Credentials move separately,
encrypted, and never touch this directory.

One thing already fixed for you: `~/.wakatime.cfg` had a live API key in it, so
what's in `dotfiles/home/` is `.wakatime.cfg.template` with the key stripped.

## The recommended path — no archive at all

Faster than the encrypted-archive dance, and nothing sensitive moves:

```bash
gh auth login                      # new token, ~30 seconds
aws configure sso                  # if your org has SSO — short-lived creds
ssh-keygen -t ed25519              # new key, add pubkey to GitHub/servers
```

For AWS without SSO: mint a fresh key pair on the new machine in IAM, then
**delete the old pair**. Two live pairs is strictly worse than one, and one of
them is on a laptop you might sell.

`~/.gnupg` is the exception — that's identity, not access, and can't be
re-issued. Migrate it deliberately with `gpg --export-secret-keys`, or via the
archive below.

## If you want the whole set moved as-is

```bash
# on the old machine
./export-secrets.sh                  # → ~/rice-secrets-<host>-<date>.tar.gz.gpg
                                     #   GPG symmetric AES-256, passphrase-protected

# move the .gpg by USB or scp — not email, not Slack, not a repo

# on the new machine
./import-secrets.sh ~/rice-secrets-thinkpad-20260805.tar.gz.gpg

# then, on both ends
shred -u ~/rice-secrets-*.tar.gz.gpg
```

`export-secrets.sh` refuses to write inside the rice bundle, never writes
plaintext to disk, chmods the output `600`, and prints a checksum. `import`
backs up whatever it shadows and re-tightens permissions to `700`/`600`.

Pick a long passphrase you haven't used elsewhere. It is the only thing between
that file and a company AWS account.

## If it leaks

```bash
gh auth logout                                   # kill the GitHub token
aws iam delete-access-key --access-key-id AKIA…  # per profile, per key
```

Then rotate anything those keys could reach, and tell whoever runs the AWS
account. Speed matters far more than tidiness here.
