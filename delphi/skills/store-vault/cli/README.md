CLI not needed — store-vault uses Read/Write tools directly.

Obsidian watches the filesystem and indexes `.md` files automatically.
No `vault-backlink.sh` script is required. The Write tool creates notes
with proper frontmatter, wikilinks, and tags in `~/.nexus/research/`.

Dataview queries, Smart Connections embeddings, and obsidian-git sync
all trigger automatically after file write.
