#!/usr/bin/perl
#
# Transwave Atom Smasher -
# Utility to create transwave compatible WAVs from any WAV
# aka a "digital phase-o-tronic wave-smashing machine" ;)
#

#
# TO DO LIST:
# - test
#

# Strict and warnings are recommended.
use strict;
use warnings;

# Modules
use File::Basename;

# Clears screen, at least on Windows platforms.
# system("cls");

# Info for runtime splash.
my $currentVersion = "0.2";
my $currentYear = "2020";

# Runtime splash.
print "Transwave Atom Smasher (Ensoniq EPS16/ASR Tool) -- Version $currentVersion, $currentYear \n\n";

# Strips the path from the Perl script/program being called.
my $executable = basename($0);

# Command Line arguments and usage response:
my $Usage = "This utility creates a transwave compatible WAV from a supplied WAV. \n\n";
$Usage .= "Usage: " . $executable . " InputWAV \n";
$Usage .= "       where InputWAV is any standard WAV file. \n\n";
$Usage .= "Such as: " . $executable . " sweep.wav \n";

# At minimum, the program has to be supplied one input file to process, so display blurb and error message if run without arguments.
die $Usage if ($#ARGV < 0);

# Get 1st argument from the command line and assume it is the filename of a WAV file.
my $WAVinput;

($WAVinput) = @ARGV;

##################################################
# THIRD-PARTY UTILITY CHECKING AND CONFIGURATION #
##################################################

# Check for SoX utility and quit if not present -- as a critical component, it's checked early before any conversions or disk writing takes place.
my $soxExe=".\\tools\\sox\\sox.exe";			# path to SoX executable, path needs double-slashes as escape
die "Critical Error: SoX has been moved or does not exist! \n" unless (-e $soxExe);

# Must call SoX as a child process via system() as environment variables cannot be passed from perl to a parent process (SoX via batch).
my $soxCmd;										# holds CMD.EXE commands to run SoX WAV conversions

#####################
# EXAMINE WAV INPUT #
#####################

# Terminate program if input WAV does not exist.
die "Critical Error: $WAVinput was specified as WAV input but cannot be found! \n" unless (-e $WAVinput);
# Check if WAV file was specified and has a reasonable size and extension.
die "Critical Error: $WAVinput was specified, but is not a WAV file! \n" unless ( (-s $WAVinput > 44) && ($WAVinput =~ /\.WAV$/i) );

# Assume the WAV file is not valid until checked.

# Opens the WAV file.
open(DATA_IN, "< $WAVinput") or die "Critical Error: Couldn't open $WAVinput as a source file! \n";
binmode(DATA_IN);
# Check that WAV file is actually a genuine WAV by examining signatures in WAV header.
my $headerRIFF;
my $headerWAVEfmt;
read(DATA_IN, $headerRIFF, 4);							# get first 4 bytes of WAV file and compare it to expected header value of "RIFF"
seek(DATA_IN, 8, 0);									# seek to 8th byte from start of WAV file
read(DATA_IN, $headerWAVEfmt, 7);						# get 7 bytes in WAV file and compare it to expected header value of "WAVEfmt"
close(DATA_IN) || warn "Error: Couldn't close $WAVinput properly! \n";
die "Critical Error: $WAVinput is corrupted or otherwise not a proper WAV! \n" unless ( ( $headerRIFF eq "RIFF" ) && ( $headerWAVEfmt eq "WAVEfmt") );

########################
# INPUT WAV CONFORMING #
########################

# Since a seemingly valid WAV was specified as a command-line argument...
# Convert input WAV to to enforce 16-bit mono for ASR/EPS compatibility.

# Filename for WAV file after it has been conformed to Ensoniq ASR/EPS standards.
my $conformedWAV = 'ensoniq_conformed.wav';

# Arguments are 16-bit, mono, little endian.
$soxCmd = " -V1 -D " . $WAVinput . " -L -b 16 " . $conformedWAV . " channels 1 silence 1 1 0.20%";
system($soxExe . $soxCmd);

######################
# READ CONFORMED WAV #
######################

# Open conformed WAV.
open(DATA_IN, "< $conformedWAV") or die "Critical Error: Conformed WAV cannot be accessed! \n";
binmode(DATA_IN);

# Creates an array for the WAV input buffer.
my @inWAV_Buffer=();
# Holds total size in bytes of conformed WAV.
my $inWAV_ByteSize=0;
# Hold total amount of sample words in conformed WAV.
my $inWAV_Samples;

# Skip over WAV header -- 44th byte from start of WAV.
seek(DATA_IN, 44, 0);

# Calculates length of the WAV file less its header -- $inWAV_ByteSize is actually the correct size of bytes because 0 is an improper index
while ( (read (DATA_IN, $inWAV_Buffer[$inWAV_ByteSize], 1)) != 0 ) {
$inWAV_ByteSize++; # Increments the bytes read counter on every pass. This will hold the amount of bytes read in for the WAV binary.
}

# Kludge to fix extra byte at end of file read in.
delete $inWAV_Buffer[$inWAV_ByteSize];

# Closes the WAV input file.
close(DATA_IN) || warn "Error: Couldn't close conformed WAV file properly! \n";

# Delete conformed WAV file. Give user a non-critical error message if file could not be erased.
unlink ($conformedWAV) || warn "Error: Conformed WAV could not be deleted. \n";

# 16-bit samples are two bytes, so simply divide amount of bytes by two to determine amount of samples.
$inWAV_Samples = $inWAV_ByteSize / 2;

print "Amount of 16-bit sample words: $inWAV_Samples \n";

########################################
# SLICE INTO MULTIPLE TRANSWAVE FRAMES #
########################################

# Each transwave frame is to be 256 samples -- so this calculates amount of frames which can be formed.
my $transwaveFrameAmt = int($inWAV_Samples/256);

print "Amount of transwave frames: $transwaveFrameAmt \n";
if ( $transwaveFrameAmt > 128 )
{
	print "Warning: Maximum of 128 allowed. WAV will be truncated to fit. \n\n";
	$transwaveFrameAmt = 128;
}
else
{
	print "\n";
}

print "Writing all transwave frame files... \n";

# Name of output file to hold each raw transwave frame.
my $outFrame='XFRAME.RAW';

# Create blank monolithic transwave.
system('if exist transwave.raw del transwave.raw >NUL');
system('copy nul transwave.raw >NUL');

# Process one file/frame per amount of frames possible.
for my $currentFrame (0..$transwaveFrameAmt-1)
{
	# Open/create binary file to write one transwave frame.
	open(DATA_OUT, "> $outFrame") or die "Error: Failed to access $outFrame for output! \n\n";
	binmode(DATA_OUT);
	
	# Write complete transwave frame to the current output file.
	# All transwave frame are exactly 512 bytes because each is 256 sample words in 16-bit form.
	my $startLoc = $currentFrame * 512;
	my $endLoc = $startLoc + 511;
	# Sequentially write each byte within range of current transwave frame.
	for ($startLoc..$endLoc)
	{
		print DATA_OUT $inWAV_Buffer[$_];
	}
	
	# Close the output file before ending routine.
	close(DATA_OUT) || die "Error: Couldn't close the output file properly! \n\n";

	#####################################################
	# PROCESS TRANSWAVE FRAME FOR PROPER ZERO CROSSINGS #
	#####################################################

	# Creates properly faded frame in the current folder.
	my $soxCmdA = " -V1 -D -r 44100 -b 16 -c 1 -e signed -t raw " . $outFrame;
	my $soxCmdB = " -r 44100 -b 16 -c 1 -e signed -t raw NEWTRANS.RAW fade p 10s 256s 10s";
	system($soxExe . $soxCmdA . $soxCmdB);
	
	# Delete original frame after processing. Give user a non-critical error message if file could not be erased.
	unlink ($outFrame) || warn "Error: Transwave frame could not be deleted. \n";
	
	# Merge current transwave frame into monolithic transwave.
	system('copy /B TRANSWAVE.RAW + NEWTRANS.RAW TRANSWAVE.RAW >NUL');
	
	# Delete processed frame after merge. Give user a non-critical error message if file could not be erased.
	unlink ('NEWTRANS.RAW') || warn "Error: Processed transwave frame could not be deleted. \n";

}

print "Transwave frames have been processed and exported! \n";

# Convert monolithic transwave into a usable WAV.
$soxCmd = " -V1 -r 44100 -b 16 -c 1 -e signed -t raw TRANSWAVE.RAW TRANSWAVE.WAV";
system($soxExe . $soxCmd);

###################
# GARBAGE REMOVAL #
###################

# Delete raw monolithic transwave after processing. Give user a non-critical error message if file could not be erased.
unlink ('TRANSWAVE.RAW') || warn "Error: Monolithic transwave could not be deleted. \n";

# End program.
exit;