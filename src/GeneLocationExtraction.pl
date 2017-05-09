#!/usr/bin/perl

use strict;
use warnings;

#   This is used to download files of the CDS from a list of given species names
# and accession numbers. With said files, data is extracted (minus the AA 
# sequence) and placed into a CVS file.

# IMPORTS ---------------------------------------------------------------------
use LWP::Simple;

# CONSTANTS -------------------------------------------------------------------
my $urlBase = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/'; # eutils base url

# MAIN ------------------------------------------------------------------------
#   Welcome message
print "####   _      _      _    \n";
print "#  # >(.)__ >(.)__ >(.)__ \n";
print "#  #  (___/  (___/  (___/ \n";
print "####\n\n\n";

#   File name for species and accession numbers
print "Accession numbers file name: ";
chomp(my $accNumFile = <STDIN>);
$accNumFile = "./Data/" . $accNumFile;
open(my $accNumReader, "<", $accNumFile) or die "Could not open that file! I failed";
print "$accNumFile has been found.\n\n";

#   Starting point for accession numbers
my $colStart = 1;

#   Create the folder to store files
print "Folder name for file storage: ";
chomp(my $folderName = <STDIN>);
print "Creating folder $folderName...\n";
mkdir ".\/Output\/$folderName";
print "Successfully made $folderName!\n\n";

#   Loop through file, grabbing accession numbers
while (my $entry = <$accNumReader>) {
    # creating the folders to store files, organized by species
    chomp($entry);
    my @row = split("\t", $entry);
    my $species = clean_name($row[0]);


    print "--  $species  ----------\n";
    # checks for existing folders and create new ones if they exist 
    my $count = 1;
    my $folderPath = $species;

    while (-d (".\/Output\/$folderName\/" . $folderPath)) { #Note: find way to have the original named A
        print "$species directory exists.\n";
        $folderPath = $species . "_(" . letter_numbering($count) . ")";
        if (-d (".\/Output\/$folderName\/" . $folderPath)) {
            $count++;
        }
    }

    # print directory info for debugging
    mkdir ".\/Output\/$folderName\/" . $folderPath;
    print "directory: $folderPath\n";

    # loops through grabbing all accession numbers in current row
    for (my $i = int($colStart); $i < @row; ++$i) {
        my $currID = $row[$i];

        # differnt ID Types: 6 digits [XX000000], 8 digit [XXXX00000000], 9 digit IDs [XXXX000000000], and more
        my $accNum;
        if ($currID  =~ m/([a-zA-Z]{1,}[0-9]{5,})/) {
            $accNum = $1;
        } else {
            print "The ID doesn't match the pattern.\n\n";
            exit;
        }

        print "$accNum\n";  #debugging
        my $accNumID = search_ID($accNum);  
        
        my $tmpfile = ".\/Output\/$folderName\/$species\/$accNum" . ".tmp";
        #print "$tmpfile\n\n";  #debugging

        # file to print GenBank file to
        open(my $fh, '>', $tmpfile) or die "I failed at";

        my $urlAdd = "efetch.fcgi?db=nuccore&id=" . $accNumID . "&rettype=fasta_cds_aa&retmode=text";
        my $FetchURL = $urlBase . $urlAdd;
        $FetchURL =~ s/\s+//g;
        #print $URL;    #debugging

        # retrive GenBank information, print and save
        my $result = get($FetchURL);
        print $fh $result;

        open(my $tmpfileReader, "<", $tmpfile) or die "Could not open that file! I failed";
        my $newfile = ".\/Output\/$folderName\/$species\/$accNum" . "[GeneLocation].csv";
        open(my $writeNew, '>', $newfile) or die "I failed at";

        # prep file
        print $writeNew "Name\tGene\tProtein\tProtein ID\tLocation\n";

        while (my $line = <$tmpfileReader>) {
            my $writeLine = "";

            if ($line  =~ m/^>/) {
                $line =~ s/\>lcl\|//g;
                my $bcount = 0;
                for my $c (split //, $line) {
                    if ($c eq "\[") {
                        if ($bcount >= 1) {
                            $writeLine = $writeLine . $c;
                        }
                        $bcount++;
                    } elsif ($c eq "\]") {
                        $bcount--;
                        if ($bcount >= 1) {
                            $writeLine = $writeLine . $c;
                        }
                    } else {
                        $writeLine = $writeLine . $c;
                    }

                    if ($bcount == 0 && $c eq " ") {
                        $writeLine = $writeLine . "\t";
                    }

                }
                
                #print $writeLine;
                print $writeNew $writeLine;
            }
        }

        close $fh;
        close $writeNew;

        #unlink $tmpfile;
            
        if(-e $tmpfile) {
            print "File was not removed.\n";
        } else {
            print "File removed.\n";
        }
    }

    print "\n\n";
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

sub clean_name {
    my $name = $_[0];
    $name =~ s/\s+$//;
    $name =~ s/(\s|\/|\\)/_/g;
    $name =~ s/(\#|\<|\$|\%|\>|\!|\&|\*|\'|\{|\}|\?|\"|\:|\@|\||\[|\])//g;
    $name =~ s/(\]|\})/\)/g;
    $name =~ s/(\[|\{)/\(/g;
    return $name;
}

sub letter_numbering {
    my $num = $_[0];
    my @letterArray = ("Z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
                   "L", "M", "N", "O", "P", "Q","R", "S", "T", "U", "V", "W", "X", "Y");
    my $letter = "";
    while ($num > 26) {
        $letter = $letterArray[($num % 26)] . $letter;
        $num = int($num/26);
    }
    $letter = $letterArray[($num % 26)] . $letter;
    return $letter;
}