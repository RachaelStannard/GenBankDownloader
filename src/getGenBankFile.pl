#!/usr/bin/perl

use strict;
use warnings;

# IMPORTS -----------------------------
use LWP::Simple;

# CONSTANTS ---------------------------
my $URLBase = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/';

# MAIN --------------------------------
print "Welcome to GenBank downloader! Ready to download files?! ^_^\n";

# 	Grab file name for accession numbers
print "What file are we accessing for the accession numbers? ";
#chomp(my $accNumFile = <STDIN>);
chomp(my $accNumFile = "TestFile.csv");
open(my $accNumReader, "<", $accNumFile) or die "Could not open that file! I failed";
print "$accNumFile has been found.\n\n";

# 	Choose starting point for accession numbers
print "Which column does the accNums begin? ";
#chomp(my $colStart = <STDIN>);
chomp(my $colStart = 2);
print "\n";

# 	Create the folder to store files
print "Now what name would you like to name the folder? ";
#chomp(my $folderName = <STDIN>);
chomp(my $folderName = "Test1");
print "Creating folder $folderName...\n";
mkdir ".\/$folderName";
print "Success!\n\n";

# 	Loop through file
while (my $entry = <$accNumReader>) {
	chomp($entry);
	my @row = split("\t", $entry);
	my $species = $row[0];
	$species =~ s/\s/_/g;
	$species =~ s/\//_/g;
	print "$species\n";
	mkdir ".\/$folderName\/$species";
	
	for (my $i = int($colStart)-1; $i < @row; ++$i) {
		my $currID = $row[$i];
		print "$currID\n";

		# 6 digits [XX000000], 8 digit [XXXX00000000], 9 digit IDs [XXXX000000000]

		my $accNum;

		if ($currID  =~ m/([a-zA-Z]{2,}[0-9]{6,})/) {
			$accNum = $1;
		} else {
			print "The ID doesn't match the pattern.\n\n";
			exit;
		}

		print "$accNum\n";
		my $accNumID = find_ID($accNum);	
		
		my $file = ".\/$folderName\/$species\/$accNum" . ".gbk";
		print "$file\n\n";

		open(my $fh, '>', $file) or die "I failed at";

		my $URLAdd = "efetch.fcgi?db=nuccore&id=" . $accNumID . "&rettype=gbwithparts&retmode=text";
		my $URL = $URLBase . $URLAdd;
		$URL =~ s/\s+//g;

		#print $URL;

		my $result = get($URL);

		print $fh $result;

		
		#print $fh $accNumID;
		#print $fh "I did it!\n";
		close $fh;
	} 

}

print "Exiting!!\n\n";

close $accNumReader;

# SUB ROUTINES ------------------------
sub find_ID {
	my $IDURL = $URLBase . 'esearch.fcgi?db=nuccore&term=' . $_[0];
	$IDURL =~ s/\s+//g;
	my $returned = get($IDURL);
	#print $returned; #testing
	my $pattern = qr/\<Id\>([^]]+)\<\/Id\>/xi;
	if ($returned =~ $pattern) {
		return $1 . "\n";
	} else {
		print "There was an error and no acession number was found.";
		exit;
	}
}