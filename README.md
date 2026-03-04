# Musician
A music mod for Luanti

## Features
- Play any instrument and song with your friends (multiplayer functionality coming soon)
- Songs are played dynamically, no audio tracks required
- Songs support unlimited concurrent parts, chords, tempo changes, etc; Your only limitation is the server's globalstep speed (dynamics and articulations coming soon)
- Parts can be added/removed during playback
- Instruments play different notes dynamically, only minimum 1 sample required
- JSON-based definition of instruments and songs
- Easy to add your own instruments and songs

### Adding new instruments/songs

Documentation for the JSON format of instruments and songs is WIP, until then please have a look at the default ones (it should be straightforward). You should only add/edit files in `data/`

All MIDI note numbers use the C3 = 60 format (https://computermusicresource.com/midikeys.html)

After adding new samples to instruments, you must run `./data/convert_sounds.sh` from the mod's root.\
**WARNING:** Audio filenames cannot have `#` in them, it is advised to use `s` instead.
