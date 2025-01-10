# Argus Scripts

This repository contains scripts that are useful for working with websites and other online services. The scripts are written in Shell and Bash, and are designed to be run on Unix-like systems.

## Requirements

- Unix-like operating system
- Bash/Zsh shell
- Curl and/or Wget

## Installation

With the current state of the scripts, the primary method of installation is using the [install_script.sh](./scripts/install_script.sh) script.

## Usage

### install_script.sh

This script will download any scripts passed to it, given the URL that points to the RAW text of the script. The script sets up the users `~/bin` directory, and adds it to the PATH in the users DOTRC file for their respective shell.

File source: [install_script.sh](./scripts/install_script.sh)

Example:

```bash
bash <(curl -s https://raw.githubusercontent.com/argus-scripts/argus-scripts/main/scripts/install_script.sh) [URL]...
```

## Contributing

Contributions are very welcome.
To learn more, see the [Contributor Guide].

## License

Distributed under the terms of the [MIT license][license],
_argus-scripts_ is free and open source software.

## Issues

If you encounter any problems,
please [file an issue] along with a detailed description.

## Credits

This project was built off of the sweat and tears
of the the bad actors it was built to fight.

<!-- github-only -->

[contributor guide]: https://github.com/xransum/argus-scripts/blob/main/CONTRIBUTING.md
[file an issue]: https://github.com/xransum/argus-scripts/issues
[license]: https://github.com/xransum/argus-scripts/blob/main/LICENSE
