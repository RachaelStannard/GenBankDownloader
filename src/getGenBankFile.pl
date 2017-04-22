#!/usr/bin/perl

use strict;
use warnings;

# IMPORTS ---------------------------------------------------------------------
use LWP::Simple;

# CONSTANTS -------------------------------------------------------------------
my $urlBase = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/';

# MAIN ------------------------------------------------------------------------

#	Welcome message
print "######################################   _      _      _    \n";
print "# Welcome to GenBank File Downloader # >(.)__ >(.)__ >(.)__ \n";
print "# Enjoy!! -Rachael Stannard          #  (___/  (___/  (___/ \n";
print "######################################\n\n\n";

# 	Grab file name for accession numbers
print "What file are we accessing for the accession numbers? ";
chomp(my $accNumFile = <STDIN>);
chomp($accNumFile);
open(my $accNumReader, "<", $accNumFile) or die "Could not open that file! I failed";
print "$accNumFile has been found.\n\n";

# 	Choose starting point for accession numbers
print "Which column does the accNums begin? ";
(my $colStart = <STDIN>);
chomp($colStart = 2);
print "\n";

# 	Create the folder to store files
print "Now what name would you like to name the folder? ";
chomp(my $folderName = <STDIN>);
print "Creating folder $folderName...\n";
mkdir ".\/$folderName";
print "Successfully made $folderName!\n\n";

# 	Loop through file, grabbing accession numbers
while (my $entry = <$accNumReader>) {
	# creating the folders to store files, organized by species
	chomp($entry);
	my @row = split("\t", $entry);
	my $species = $row[0];
	$species =~ s/(\s|\/)/_/g;
	#$species =~ s/\//_/g;	#debugging
	print "$species\n";
	mkdir ".\/$folderName\/$species";
	
	# loops through grabbing all accession numbers in current row
	for (my $i = int($colStart)-1; $i < @row; ++$i) {
		my $currID = $row[$i];
		#print "$currID\n";	#debugging

		# differnt ID Types: 6 digits [XX000000], 8 digit [XXXX00000000], 9 digit IDs [XXXX000000000]
		my $accNum;
		if ($currID  =~ m/([a-zA-Z]{2,}[0-9]{6,})/) {
			$accNum = $1;
		} else {
			print "The ID doesn't match the pattern.\n\n";
			exit;
		}
		
		print "$accNum\n"; 	#debugging
		my $accNumID = search_ID($accNum);	
		
		my $file = ".\/$folderName\/$species\/$accNum" . ".gbk";
		#print "$file\n\n";	#debugging

		#file to print GenBank file to
		open(my $fh, '>', $file) or die "I failed at";
		my $urlAdd = "efetch.fcgi?db=nuccore&id=" . $accNumID . "&rettype=gbwithparts&retmode=text";
		my $FetchURL = $urlBase . $urlAdd;
		$FetchURL =~ s/\s+//g;
		#print $URL;	#debugging

		#retrive GenBank information, print and save
		my $result = get($FetchURL);
		print $fh $result;
		close $fh;
	} 

}

close $accNumReader;
print "\nJob is completed with no known errors.\n\n";

# SUB ROUTINES ----------------------------------------------------------------
sub search_ID {
	my $searchURL = $urlBase . 'esearch.fcgi?db=nuccore&term=' . $_[0];
	$searchURL =~ s/\s+//g;
	my $id = get($searchURL);
	my $pat = qr/\<Id\>([^]]+)\<\/Id\>/xi;
	if ($id =~ $pat) {
		return $1 . "\n";
	} else {
		print "\n!!!\nThere was an error and no acession number was found.\n!!!\n";
		exit;
	}
}
