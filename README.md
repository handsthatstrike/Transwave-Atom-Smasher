# Transwave-Atom-Smasher
Create Ensoniq transwave-ready waveforms from standard WAVs. Transwave Atom Smasher takes each supplied WAV from the "[WAV_IN]" folder and rips it into individual frames of 256 samples, processes each frame (maximum of 128), and then reforms them into one WAV which is much like the original.

You can supply multiple WAVs at once, but each individual WAV is processed individually as its own transwave sound.

While this is a Perl script at its core, it currently only runs on Windows due to dependencies and batch scripting.

- Users without Perl can run "Transwave Atom Smasher v0.2 (EXE).bat" directly.

- Users with Perl installed can run "Transwave Atom Smasher v0.2 (Perl).bat" which provides for making changes to the Perl script in the "tools" folder.
