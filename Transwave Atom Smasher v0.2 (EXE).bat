@echo off
echo ########################################
echo # Ensoniq Transwave Atom Smasher v0.20 #
echo ########################################
echo.
echo Place all WAVs to be smashed into the "[WAV_IN]" folder before proceeding.
echo.
echo Each supplied WAV will be broken into a maximum of 128 frames with a frame 
echo size of 256 samples, and then reconstructed as a single transwave-ready 
echo WAV file closely resembling the original.
echo.
echo All transwave-ready WAV will be output to the "[XWAV_OUT]" folder.
echo.
pause
echo.

rem -- check for WAV input folder
if not exist .\[WAV_IN] (
	echo Warning: WAV input folder cannot be found. Creating...
	mkdir .\[WAV_IN] >NUL
	echo.
)

rem -- check for input WAVs
if exist .\[WAV_IN]\*.WAV (
	echo Smashing...
	for /r .\[WAV_IN] %%F in (*.WAV) do (
		rem -- duplicate WAV
		copy "%%F" %%~NF.WAV >NUL
		echo.
		.\tools\TranswaveAtomSmasher.exe "%%~NF.WAV"
		ren TRANSWAVE.WAV %%~NF-XWV.WAV >NUL
		if not exist .\[XWAV_OUT] mkdir [XWAV_OUT]
		move %%~NF-XWV.WAV .\[XWAV_OUT] >NUL
		rem -- clean temporary duplicate
		del %%~NF.WAV >NUL
	)
) else echo No WAVs found to smash!
echo.
echo All WAV files have been smashed. Look in [XWAV_OUT] folder.
echo.
pause