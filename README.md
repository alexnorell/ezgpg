# EZ-GPG

A quick way to get GPG set up.

- Configure GPG for best practices
- Create GPG Primary key and Subkeys
- Configure Git to sign commits
- Set up SSH agent via GPG

This all comes from a single `zsh` script that can be curled.

## Setup

The script checks for the presence of the following tools in the `PATH`:

- `gpg`
- `ykman`
- `git`

If you don't have them, use your package manager to install them.

