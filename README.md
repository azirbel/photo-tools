# Photo Tools

## rename.rb

Rename photos to android convention (e.g. `IMG_YYYYMMDD_hhmmss.jpg`) using EXIF data.

Non-destructive: photos are copied to a [input-folder]-new folder and then renamed.

### Usage:

```
./rename.rb [input-folder] (options)
```

### Help:

```
./rename.rb -h
```

### Options:

Option | Shorthand | Description
--- | --- | ---
`--create-month-folders` | `-m` | Create subfolders for each month
`--suffix` | `-s` | Add a suffix

### More information

Photos exported from iPhone and other programs have poor and unhelpful names,
like `3.jpg`. This means that when you combine your photos with someone else's,
they get out of order.

Android's naming convention (`YYYYMMDD-hhmmss`) is much more helpful, because
photos automatically stay in chronological order.

This script uses EXIF data to rename a folder of photos to android format.

It also changes the "created at" / "modified at" dates of the new files to
match the date the photos were taken.

Example input:

```
input-folder/1.jpg
input-folder/2.JPG
input-folder/unhelpful-name.png
input-folder/downloaded-from-facebook.MOV
```

Example output:

```
input-folder-new/IMG_20160102_030405.jpg
input-folder-new/IMG_20160102_334455.jpg
input-folder-new/IMG_20160102_444444.png
input-folder-new/IMG_20161212_111111.mov
```

#### Automatically create per-month folders

```bash
./rename.rb input-folder --create-month-folders

# OR

./rename.rb input-folder -m
```

Output:

```
input-folder-new/2016_01/IMG_20160102_030405.jpg
input-folder-new/2016_01/IMG_20160102_334455.jpg
input-folder-new/2016_01/IMG_20160102_444444.png
input-folder-new/2016_12/IMG_20161212_111111.mov
```

#### Add a suffix

```bash
./rename.rb input-folder --suffix=mine

# OR

./rename.rb input-folder -s mine
```

Output:

```
input-folder-new/IMG_20160102_030405_mine.jpg
input-folder-new/IMG_20160102_334455_mine.jpg
input-folder-new/IMG_20160102_444444_mine.png
input-folder-new/IMG_20161212_111111_mine.mov
```

#### Missing EXIF data

Files with missing exif data will be put in a subfolder indicating that, e.g.

```
input-folder-new/missing-exif-data/1.jpg
```
