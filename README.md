#

## File structure

### Base directory for *Development*

Base directory for developmen: `./run/dev`


### Base directory for *Production/Radshift Host*

Physical Base directory on the Radshift Host: `/var/rs-root`


### Subdiretories

The following subdirectories are specified relative to the base directory for the corresponding environment (see above; don't mind the leading `/`, the paths are relative)

#### `/etc`: Config files

| Dir | Explanation |
|--|--|
| `/etc/core` | Config files for the core components |
| `/etc/<backend name>` | Config files for the corresponding backend |


#### `/var`: App data

| Dir | Explanation |
|--|--|
| **`/var`**: | |
| `/var/core` | App data of the core components (e.g. lowdb data file) |
| `/var/<backend name>` | App data of the corresponding backend |


### Minimal file structure example:

```
/var/rs-root
    |
    + /etc/core
    + /var/core
```