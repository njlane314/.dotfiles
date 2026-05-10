# Project Templates

Small starter trees for new projects. Copy one, rename the project-specific
identifiers, then run its `make check`.

```sh
cp -R templates/python ~/programs/new-python-project
```

Related project skeleton repos live under `repos/` as independent nested Git
repositories:

- `repos/stdmk`: standard Unix-shaped repository surface: `./configure`,
  `make`, `make check`, `make install`, `make clean`, and `make distclean`.
- `repos/mkskel`: language-extensible coding workstation with short make
  commands, source/test separation, cached builds, and bundle/run helpers.
