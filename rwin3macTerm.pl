#!/usr/bin/perl -w
##
## FILE: rwin3macTerm.pl
##
## PURPOSE: Open a remote window to the named machine
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

#my $machinesFile = "$ENV{HOME}/bin/rwin-data";
my $machinesFile = "$ENV{HOME}/src/git/github/rwin/rwin-data";
my $colorsFile = "$ENV{HOME}/src/git/github/rwin/colors.txt";
my $linuxUser = 'tanakak'; ## default if not in rwin-data access column as 'user@host'
#my $DefaultDomain = '.ngdc.noaa.gov';
my $DefaultDomain = '';
my $hostCmd = '/usr/bin/host';
#my $sshCmd = '/usr/bin/ssh -Y';
my $sshCmd = '/bin/echo';

my $termCmd = qq!osascript -e 'tell application "Terminal" to do script "exec ssh ACCESS"'!
  . qq! -e 'tell application "Terminal" to set normal text color of window 1 to FGCOLOR'!
  . qq! -e 'tell application "Terminal" to set background color of window 1 to BGCOLOR'!;
my $Debugging = 1;

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
    my ($name, $access, $aka, $ip, $fg, $bg) = split(/\s*\|\s*/, $row);
    print join(' , ', $name, $access, $aka, $ip, $fg, $bg). "\n" if $Debugging;
    my $mrec = { ## Create a machine record
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
    printf "%-15s | %-27s | %-20s | %-15s | %-15s | %s\n", 'machine', 'ACCESS', 'AKA', 'IP', 'FG', 'BG';
    my @machList = (sort keys %machines);
    foreach $m (@machList) {
        $mrec = $machines{$m};
        #print "\nm=$m\n";
        #print "machines{$m}{ACCESS}=$machines{$m}{ACCESS}\n";
        #print "mrec->{ACCESS}=$mrec->{ACCESS}\n";
        printf "%-15s | %-27s | %-20s | %-15s | %-15s | %s\n", $m, $mrec->{ACCESS}, $mrec->{AKA}, $mrec->{IP}, $mrec->{FG}, $mrec->{BG};
    }
    #exit 0;
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
#$lookupHost =~ /.*@(\w+)/ and do {
#    $lookupHost = $1;
#};

if ($lookupHost !~ /.(gov|edu|net|org|mil|com)$/) {
    $lookupHost .= $DefaultDomain;
}

my $fgcolor = $machines{$choice}{FG};
my $appleFgColor = &getAppleColor($fgcolor, "{0, 0, 0}");

my $bgcolor = $machines{$choice}{BG};
my $appleBgColor = &getAppleColor($bgcolor, "{65535, 65535, 65535}");

$termCmd =~ s/NAME/$choice/;
$termCmd =~ s/FGCOLOR/$appleFgColor/;
$termCmd =~ s/BGCOLOR/$appleBgColor/;
if ($lookupHost =~ /\s*(.*)\@(.*)/) {
  $linuxUser = $1;
  $justHost = $2;
} else {
    $justHost = $lookupHost;
}
print "linuxUser='$linuxUser', justHost='$justHost'\n" if $Debugging;
$termCmd =~ s/ACCESS/$linuxUser\@$justHost/;

print `$hostCmd $justHost`;

print"system($termCmd)\n" if $Debugging;
system($termCmd);

##*****************************************************************
##
##  getAppleColor()
##
##  &getAppleColor(color, defaultAppleColor)
##
##  Convert the color into an apple color. The color can be either
##  - #aabbcc Red-Green-Bue hex color
##  - colorName (camelcase, no spaces)
##  looks up color name from colors.txt
##  defaultAppleColor is returned if the color is not found in colors.txt
##
##*****************************************************************
sub getAppleColor {
  local($colorName, $defaultAppleColor) = @_;
  local $appleColor;
  print "look up color $colorName, default is $defaultAppleColor\n" if $Debugging;
  $colorName =~ s/,//g; ## strip out any commas
  local $hexColorPattern = '#([0-9a-fA-F]{2}),?([0-9a-fA-F]{2}),?([0-9a-fA-F]{2})';
  local ($r, $g, $b);
  if ($colorName =~ /${hexColorPattern}/) {
    $r = $1;
    $g = $2;
    $b = $3;
    print "r=$r, g=$g, b=$b\n" if $Debugging;
    $appleColor = '{' . hex($r)*257 . ', ' . hex($g)*257 . ', ' . hex($b)*257 . '}';
  } else {
    print "grep -i \"^${colorName}\\s\" ${colorsFile}\n" if $Debugging;
    $hexColor = `grep -i "^${colorName}\\s" ${colorsFile}`;
    chomp($hexColor);
    print "grep hexColor = '$hexColor'\n" if $Debugging;
    if ($hexColor =~ /.*\s${hexColorPattern}/) {
      $r = $1;
      $g = $2;
      $b = $3;
      print "grep hex r=$r, g=$g, b=$b\n" if $Debugging;
      $appleColor = '{' . hex($r)*257 . ', ' . hex($g)*257 . ', ' . hex($b)*257 . '}';
    } else {
      print "using default color $defaultAppleColor\n" if $Debugging;
      $appleColor = $defaultAppleColor;
    }
  }
  print "appleColor = '$appleColor'\n" if $Debugging;
  return $appleColor;
}