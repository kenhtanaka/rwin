#!/usr/bin/perl
##
## FILE: rwin.pl
##
## PURPOSE: Open a remote window to the named machine using a gnome-terminal.
##          Uses gconftool-2 to set foreground text and window background colors
##          so that ssh sessions are color coded based on remote destination.
##
## USAGE: rwin.pl -r
##        {Set up gnome-terminal profiles, only needed one time after editing the
##         %machines list in this file.}
##
##        rwin.pl <machine name>
##        {Open a new gnome-terminal and ssh to that system}
##
##        rwin.pl
##        {Present a menu of systems to log into. '0' or CTRL-C exits.}
##
##        This script is able to configure existing gnome-terminal color profiles,
##        but does not create them. This script will ignore the Default profile.
##        Manually create as many additional profiles as there are entries in the
##        %machines configuration list.
##
## AUTHOR: Ken Tanaka

## /usr/bin/showrgb | less can help you choose colors.
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

## AKA: Also-Known-As field is just a comment displayed in menu mode.
##      You can include an IP address if you want to visually compare to the 'host'
##      command output for security or password purposes.
%machines = (
    ##'example' => {    ACCESS => 'example.ngdc.noaa.gov',
    ##                  AKA    => 'example format, 140.172.180.11',
    ##                  COLORS => ['foreground text', 'window background'] },
    'lion'      => {    ACCESS => 'lion',
                        AKA    => '"cron server", 140.172.180.54',
                        COLORS => ['red4', '#fffff0'] },
    'tabby'     => {    ACCESS => 'tabby',
                        AKA    => 'local workstation',
                        COLORS => ['black', '#eeddcc'] },
);

$UseTestList = 0;
if ($UseTestList) {
    %machines = (
        'test'     => {    ACCESS => 'test',
                           AKA    => 'test uncommented',
                           COLORS => ['blue1', '#bb,ee,ff'] },
    );
}


$Reconfigure = 0;
$Debugging = 0;

if ($ARGV[0] eq '-r') {
    $Reconfigure = 1;
    print "Reconfigure mode ($ARGV[0])\n";
    shift @ARGV;
}

## Number of machines
$machineCount = keys %machines;
print "machineCount = $machineCount\n" if $Debugging;

$DefaultDomain = '.ngdc.noaa.gov';
$hostCmd = '/usr/bin/host';
$sshCmd = '/usr/bin/ssh -Y';
#$Geom = '-geom 80x40+20+20';
$Geom = '--geometry 140x40+20+20';
#$Font = '-font "-adobe-courier-medium-r-*-*-18-*-*-*-*-*-iso8859-1"';
$gconftool = '/usr/bin/gconftool-2';
$gtermCmd = qq'/usr/bin/gnome-terminal $Geom --title="NAME" --tab-with-profile-internal-id="PROFILE" --command="$sshCmd ACCESS" &';

## Get gnome-terminal profile list
## Leave 'Default' alone, use the rest of the Profile0...ProfileN for gnome terminal
## customization to match the machines hash.
$gconftoolCmd = "$gconftool --get /apps/gnome-terminal/global/profile_list";

print "system($gconftoolCmd)\n" if $Debugging;
chomp($profiles = `$gconftoolCmd`);

print "profiles=$profiles\n" if $Debugging;
@profileList = [];
if ($profiles =~ /^\[(.*)\]$/) {
    @profileList = sort split(/,/, $1);
    shift @profileList; ## drop 'Default' off the beginning
} else {
    print "profiles=$profiles\n";
    die 'profiles not in expected format of: "[Default,Profile0,Profile1,...ProfileN]"';
}

## Exit if there are not enough Profile# slots
print "profileList=" . join(':', @profileList) . "\n" if $Debugging;
$profileCount = @profileList;
print "profileCount=$profileCount\n" if $Debugging;
if ($profileCount < $machineCount) {
    die "There are not enough profile slots. Create profiles for $machineCount terminals";
}

## Set up gnome-terminal parameters: visible_name, foreground_color, background_color
my $gtProfileId;
my @machList = (sort keys %machines);
$i = 0;
foreach $m (@machList) {
    $gtProfileId = "Profile$i";
    $machines{$m}{PROFILE} = $gtProfileId;
    ## Set up gnome-terminal parameters:
    ## visible_name, foreground_color, background_color
    if ($Reconfigure) {
        print '=' x 22 . " Configuring '$m' in profile $gtProfileId\n" if $Debugging;
        my $fgcolor = $machines{$m}{COLORS}[0];
        print "fgcolor before: $fgcolor, " if $Debugging;
        $fgcolor =~ s/,//g; ## strip out any commas
        print "after: $fgcolor\n" if $Debugging;

        my $bgcolor = $machines{$m}{COLORS}[1];
        $bgcolor =~ s/,//g; ## strip out any commas

        $gconftoolCmd = "$gconftool"
            . qq' --set "/apps/gnome-terminal/profiles/$gtProfileId/visible_name"'
            . qq' --type string "$m"';
        print "gconftoolCmd = $gconftoolCmd\n" if $Debugging;
        system($gconftoolCmd);

        $gconftoolCmd = "$gconftool"
            . qq' --set "/apps/gnome-terminal/profiles/$gtProfileId/foreground_color"'
            . qq' --type string "$fgcolor"';
        print "gconftoolCmd = $gconftoolCmd\n" if $Debugging;
        system($gconftoolCmd);

        $gconftoolCmd = "$gconftool"
            . qq' --set "/apps/gnome-terminal/profiles/$gtProfileId/background_color"'
            . qq' --type string "$bgcolor"';
        print '-' x 22 if $Debugging;
        print "\ngconftoolCmd = $gconftoolCmd\n" if $Debugging;
        system($gconftoolCmd);
    }
    $i++;
}
    
if ($Reconfigure) {
    ## Set the name of unused profiles to "..unused #.." so previous names aren't
    ## left behind if the configured list gets shorter. This avoids duplicate names 
    ## that can be confusing.
    if ($i < $profileCount) {
        for (; $i < $profileCount; $i++) {
            $gtProfileId = "Profile$i";
            $gconftoolCmd = "$gconftool"
                . qq' --set "/apps/gnome-terminal/profiles/$gtProfileId/visible_name"'
                . qq' --type string "..unused $i.."';
            print "gconftoolCmd = $gconftoolCmd\n" if $Debugging;
            system($gconftoolCmd);
        }
    }
}

print "gtermCmd = $gtermCmd\n" if $Debugging;

if (scalar(@ARGV) and not exists($machines{$ARGV[0]})) {
    print "Unknown system $ARGV[0]. Choose a number\n";
}

if (not scalar(@ARGV) or not exists($machines{$ARGV[0]})) {
    $i = 1;
    #my @machList = (sort keys %machines);
    foreach $m (@machList) {
        printf "%2d: %-15s ", $i, $m;
        if (defined $machines{$m}{AKA}) {
            print "($machines{$m}{AKA})\n";
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

print `$hostCmd $lookupHost`;

$gtermCmd =~ s/NAME/$choice/;
$gtermCmd =~ s/PROFILE/$machines{$choice}{PROFILE}/;
$gtermCmd =~ s/ACCESS/$machines{$choice}{ACCESS}/;

print "system($gtermCmd)\n" if $Debugging;
system($gtermCmd);

