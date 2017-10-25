#!/usr/bin/perl -w
##
## FILE: rwin3.pl
##
## PURPOSE: Open a remote window to the named machine using xterms
##
## Mac OS X version
##
##  Related Files:
##      rwin-data: remote window information, flatfile database (same data file is used by makeBashrc.groovy)
##
##

## /usr/bin/showrgb | less can help you choose colors.
## http://www.color-hex.com/color-names.html
## Or use https://www.allscoop.com/tools/Web-Colors/web-colors.php

## Commas can be inserted into colors for readability: #ff,e8,e8
## Color examples:
##     '#bfe'
##     '#bbfef8'
##     '#bb,fe,f8'
##     'black'
##     'green2'
##     'misty rose'
##     'MistyRose'
##     '#bbbbffffffff'
##     '#bbbb,ffff,ffff'

my $machinesFile = "$ENV{HOME}/bin/rwin-data";
$DefaultDomain = '.ngdc.noaa.gov';
$hostCmd = '/usr/bin/host';
$sshCmd = '/usr/bin/ssh -Y';
$SavedLines = '-sl 2000';
#$Geom = '-geom 80x40+20+20';
$Geom = '-geom 140x40-20-20';
$Font = '-font "-adobe-courier-medium-r-*-*-18-*-*-*-*-*-iso8859-1"';
$xtermCmd = qq'/usr/X11R6/bin/xterm $Geom $Font $SavedLines -sb -fg "FGCOLOR" -bg "BGCOLOR" -T "NAME" -e $sshCmd ACCESS &';
$Debugging = 0;

##*****************************************************************************
##
##  Set up a hash of machine records from the rwin-data file.
##
##  Data structure desired:
##  machines{name}:
##      S/mRec{}:
##          ACCESS  => C[]  ## machine name ( ".ngdc.noaa.gov" may be omitted)
##          AKA     => C[]  ## Also known as comment
##          IP      => C[]  ## IP address
##          FG      => C[]  ## Foreground text color
##          BG      => C[]  ## Background text color
##*****************************************************************************
my %machines = ();
open (my $datafile, "<$machinesFile") or die "Could not read data file '$machinesFile' $!";
while (not eof($datafile)) {
    my $row = readline($datafile);
    chomp $row;
    next if ($row =~ /^#/); ## Skip comments
    next if ($row =~ /^$/); ## Skip blank lines
    ($name, $access, $aka, $ip, $fg, $bg) = split(/\s*\|\s*/, $row);
    print join(' , ', $name, $access, $aka, $ip, $fg, $bg). "\n" if $Debugging;
    $mrec = { ## Create a machine record
        ACCESS  => $access,
        AKA     => $aka,
        IP      => $ip,
        FG      => $fg,
        BG      => $bg
    };
    $machines{$name}=$mrec;
}
close $datafile;

if ($Debugging) {
    my @machList = (sort keys %machines);
    foreach $m (@machList) {
        $mrec = $machines{$m};
        #print "\nm=$m\n";
        #print "machines{$m}{ACCESS}=$machines{$m}{ACCESS}\n";
        #print "mrec->{ACCESS}=$mrec->{ACCESS}\n";
        printf "%-15s | %-27s | %-20s | %-15s | %-15s | %s\n", $m, $mrec->{ACCESS}, $mrec->{AKA}, $mrec->{IP}, $mrec->{FG}, $mrec->{BG};
    }
    exit 0;
}

if (scalar(@ARGV) and not exists($machines{$ARGV[0]})) {
    print "Unknown system $ARGV[0]. Choose a number\n";
}

if (not scalar(@ARGV) or not exists($machines{$ARGV[0]})) {
    my $i = 1;
    my @machList = (sort keys %machines);
    foreach $m (@machList) {
        printf "%2d: %-15s ", $i, $m;
        if (defined $machines{$m}->{AKA}) {
            print "($machines{$m}->{AKA})\n";
        } else {
            print "\n";
        }
    $i++;
    }
    print "Choose a system #: ";
    $choice = <STDIN>;
    exit if ($choice < 1 or $choice > $i);
    $choice = $machList[$choice - 1];
} else {
    $choice = shift;
}

$lookupHost = $machines{$choice}{ACCESS};
$lookupHost =~ /.*@(\w+)/ and do {
    $lookupHost = $1;
};

if ($lookupHost !~ /.(gov|edu|net|org|mil|com)$/) {
    $lookupHost .= $DefaultDomain;
}

my $fgcolor = $machines{$choice}{FG};
$fgcolor =~ s/,//g; ## strip out any commas

my $bgcolor = $machines{$choice}{BG};
$bgcolor =~ s/,//g; ## strip out any commas

$xtermCmd =~ s/NAME/$choice/;
$xtermCmd =~ s/FGCOLOR/$fgcolor/;
$xtermCmd =~ s/BGCOLOR/$bgcolor/;
$xtermCmd =~ s/ACCESS/$machines{$choice}{ACCESS}/;

print `$hostCmd $lookupHost`;

#print"system($xtermCmd)\n";
system($xtermCmd);

