# Sync Your Config (SYC)

This repository allows you to **synchronize** all **your config** files (e.g., shell themes, aliases, scripts, Git configs, SSH configs, *non-sensitive* access tokens, etc.) across all your devices such as private laptops, work machines, cluster nodes, etc. with little effort. No need to copy your config files back and forth anymore or work with multiple inconsistent environments—keep everything configured at a single place 🐳

Key features of SYC:
- **Hierarchical config files**: Synchronize your config files at different hierarchical levels of devices (e.g., `global`, `os`, `local`).
- **Bootstrapped config files**: Combine your config files from different hierarchies (e.g., `[global]/.zshrc` > `[os]/.zshrc` > `[local]/.zshrc`).
- **Shared config files**: Share your config files across specific devices independent of the hierarchy.
- **Version control**: Track changes to your config files with Git.

> [!WARNING]
> Non-sensitive access tokens could be (up to your own discretion) HuggingFace, Kaggle, W&B, etc. access tokens. Please do not use this tool to sychronize your private SSH keys, as this is considered bad practice.

## SYC philosophy

### Basic features

The key idea is to symlink all config files into (your *private* fork of) this repository, such that it can be tracked by Git and synchronized over Github. For example, you can link your `.gitconfig` file into the global scope using
```bash
syc link global ~/.gitconfig
```
to synchronize it with all other devices. After you added or made changes to your config files, you can push the updates to Github using
```bash
syc sync
```
and then run the same command on your other devices (whenever you are using them) to pull the newest updates.

### Advanced features
But sometimes, config files only apply to certain OS or only to specific devices. This is why SYC uses a hierarchical configuration structure to allow config files to be shared at different levels.
- **`[global]` scope** (path: `$SYC/global`): This scope contains config files shared across all devices.
- **`[os]` scope** (path: `$SYC/os/<OS>`): This scope contains config files shared across devices using the same OS (e.g., Linux, Linux_WSL, Mac, Windows). The OS is determined based on the command `uname -a`.
- **`[local]` scope** (path: `$SYC/local/<HOSTNAME>-<OS>`): This scope contains config files shared across devices using the same hostname and OS (i.e., typically not shared with other devices). The hostname is determined based on the command `hostname` or based on the `~/.syc_hostname` file if it exists (checkout FAQ for more information).

To add more flexibility to the hierarchical structure, SYC provides the following additional features:
- **Bootstrapping** (path: `$SYC/bootstrap`): Bootstrapped config files combine the config files at different hierarchical levels, with lower level config files overwriting or complementing the higher level config files. For example, `.zshrc` can be bootstrapped in order to combine general shell configurations in `[global]/.zshrc` with device-specific shell configurations in  `[local]/.zshrc`.
- **Sharing** (path: `$SYC/share`): Shared config files can be shared across specific devices independent of their hierarchy. For example, one could add
    ```bash
    [[ ! "${PATH}" =~ "${SYC_SHARE}/slurm" ]] && {
        export PATH="${SYC_SHARE}/slurm:${PATH}"
    }
    ```
    to all `[local]/.zshrc` of Slurm-based cluster nodes to share some Slurm helper scripts found in `share/slurm`.

## Setup

### Step 1: Create a private fork
Create a *private* fork of this repository, as you probably do not want everybody to see your personal config files, which potentially include your non-sensitive access tokens.

### Step 2: Personalize SYC
This repository provides an example structure based on my personal setup using [zsh](https://zsh.org/), [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh/) and the [powerlevel10k](https://github.com/romkatv/powerlevel10k/) theme. If you use the same setup and would like to proceed with my default configurations, feel free to skip this step.

If you want to use your own setup and theme, you first have to personalize SYC. As I do not know your setup, I will instead walk you through the basic steps of my own setup and you need to figure out how you can adapt it to yours.

SYC consists of two key components:
- [`sync-your-config.zsh`](sync-your-config.zsh): This file implements all SYC commands and needs to be sourced into every shell session in order to use SYC. *This file does not need to be changed.*
- [`bootstrap/.zshrc`](bootstrap/.zshrc): This file implements the bootstrapping mechanism for the `.zshrc` config file. *This file can be changed.*

The key idea is to symlink `~/.zshrc` to `bootstrap/.zshrc` such that each shell session sources all relevant config files. Specifically, my personal [`bootstrap/.zshrc`](bootstrap/.zshrc) sources the following files in the following order:
```shell
# SYC commands (required to use SYC)
$SYC/sync-your-config.zsh

# oh-my-zsh configuration (bootstrapped)
[global]/.zshrc-omz # if exists
[os]/.zshrc-omz     # if exists
[local]/.zshrc-omz  # if exists

# oh-my-zsh
$ZSH/oh-my-zsh.sh   # if exists

# powerlevel10k configuration
~/.p10k.zsh         # if exists

# profile configuration (bootstrapped)
[global]/.zshrc     # if exists
[os]/.zshrc         # if exists
[local]/.zshrc      # if exists
```
- SYC replaces `[global/os/local]` with the respective path of the configuration hierarchy.
- SYC provides the internal commands `_syc_bootstrap` and `_syc_source` to bootstrap or source config files. This allows you to print a list of files sourced into the current shell session using the command `syc sourced`.
- In my personal setup, `.zshrc-omz` is used to configure oh-my-zsh, while `.zshrc` is used to configure my personal shell profile.
- In my personal setup, `~/.p10k.zsh` is actually a symlink to `[global]/.p10k.zsh`.

To personalize SYC, you might want to first clone your repository into one of your devices using
```bash
git clone <your-syc-repo> ~/.config/syc
```
and then modify the bootstrapping mechanism, oh-my-zsh configuration, powerlevel10k configuration, and/or your profile configuration.

### Step 3: Setup SYC
To setup SYC on your devices, run
```bash
git clone <your-syc-repo> ~/.config/syc
~/.config/syc/install.zsh
```

The `install.zsh` script executes the following steps, which you can also follow manually:
1. Source the main SYC script. This allows you to use all SYC commands in your *current* shell session to proceed with the installation.
    ```bash
    source "~/.config/syc/sync-your-config.zsh"
    ```
2. Bootstrap your `~/.zshrc` config file. This is the key step, as it ensures that every *new* shell session sources all relevant config files as described in step 2.
    ```bash
    # symlink: ~/.zshrc -> bootstrap/.zshrc
    syc bootstrap ~/.zshrc
    ```
3. (optional) Link all of your other config files.
    ```bash
    # symlink: ~/.p10k.zsh -> [global]/.p10k.zsh
    syc link global ~/.p10k.zsh
    # symlink: ~/.p10k.zsh -> [global]/.gitconfig
    syc link global ~/.gitconfig
    ```

If you have your own setup, you might want to personalize the `install.zsh` script.


## Usage

###
To print a list of available commands, run
```bash
syc help
```

### Link config files

To link a config file into the SYC repository, use
```bash
syc link [global|os|local] <source> {<target>}
```

Examples:
```bash
# symlink: ~/.zshrc -> [global]/.zshrc
syc link global ~/.zshrc

# symlink: ~/.ssh/config -> [global]/.ssh/config
syc link global ~/.ssh/config
# symlink: ~/.ssh/config -> [global]/.ssh_config
syc link global ~/.ssh/config .ssh_config
```

> [!NOTE]
> On Windows, you need to admin privileges to create symbolic links.

### Synchronize changes

To synchronize your changes to the config files, run
```bash
syc sync
```

> [!NOTE]
> Internally, this command executes the following steps:
> 1. Stash any uncommitted changes.
> 2. Pull the latest changes using rebase.
> 3. Apply the stashed changes.
> 4. Commit the changes.
> 5. Push the changes.

> [!WARNING]
> Sometimes, merge conflicts might occur, which you need to resolve manually. In this case, SYC will not commit the changes automatically, but you can run `syc sync` again after resolving the conflicts.

## FAQ
- Can I use SYC with bash?
    > Currently, SYC is implemented in zsh only. However, I tried to mark all zsh-specific lines of code with `# BASH use ...`. With some effort, it should be possible to adapt the code to bash. Feel free to provide a PR on this.
- Can I also bootstrap other config files?
    > Currently, bootstrapping has been only implemented for `.zshrc`, as there is currently no (personal) need to bootstrap other config files such as Git or SSH configs and it is also unclear, how this could be done for other config files. Feel free to provide a PR on this.
- I want to use the same local configuration on devices with different hostnames, such as the different nodes of the same cluster. What can I do?
    > You can create the file `~/.syc_hostname` containing the canonical hostname you want to give for all these devices. SYC will use this hostname instead of the actual hostname of the device and hence allows to share the local configuration.

Still anything unclear? Feel free to checkout [`sync-your-config.zsh`](sync-your-config.zsh) if you are confident with zsh or open an issue.

## License

All content in this repository is licensed under the MIT license. See [LICENSE](LICENSE) for details.
