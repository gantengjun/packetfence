#!/usr/bin/perl -w

# Copyright 2007-2008 Inverse groupe conseil
#
# See the enclosed file COPYING for license information (GPL).
# If you did not receive this file, see
# http://www.fsf.org/licensing/licenses/gpl.html
#

use strict;
use warnings;
use diagnostics;

use Net::SNMP;
use Log::Log4perl;
use Config::IniFiles;
use lib '/usr/local/pf/lib';
use pf::util;
use pf::locationlog;
use pf::config;
use pf::SwitchFactory;

my $mac = $ARGV[0];

if ($mac =~ /^([0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2}:[0-9a-zA-Z]{2})$/) {
    $mac = $1;
} else {
    die "Bad MAC $mac";
}

pflogger("flip.pl called with $mac", 8);

my %switchConfig;
tie %switchConfig, 'Config::IniFiles', (-file => "/usr/local/pf/conf/switches.conf");
my @errors = @Config::IniFiles::errors;
if (scalar(@errors)) {
    pflogger("Error reading config file: " . join("\n", @errors), 1);
    return 0;
}

#remove trailing spaces..
$switchConfig{'default'}{'communityTrap'}=~s/\s+$//;


my $locationlog_entry = locationlog_view_open_mac($mac);
if ($locationlog_entry) {
    my $switch_ip = $locationlog_entry->{'switch'};
    my $ifIndex = $locationlog_entry->{'port'};
    pflogger("switch port for $mac is $switch_ip ifIndex $ifIndex", 8);
    if ($ifIndex eq 'WIFI') {
        my ($session,$err) = Net::SNMP->session(
            -hostname => '127.0.0.1',
            -port => '162',
            -version => '1',
            -community => $switchConfig{'default'}{'communityTrap'});

        $session->trap(
            -genericTrap => Net::SNMP::ENTERPRISE_SPECIFIC,
            -agentaddr => $switch_ip,
            -varbindlist => [
            '1.3.6.1.6.3.1.1.4.1.0', Net::SNMP::OBJECT_IDENTIFIER, '1.3.6.1.4.1.29464.1.2',
            "1.3.6.1.4.1.29464.1.3", Net::SNMP::OCTET_STRING, $mac,
            ]
        );

    } else {
        my ($session,$err) = Net::SNMP->session(
            -hostname => '127.0.0.1',
            -port => '162',
            -version => '1',
            -community => $switchConfig{'default'}{'communityTrap'});

        $session->trap(
            -genericTrap => Net::SNMP::ENTERPRISE_SPECIFIC,
            -agentaddr => $switch_ip,
            -varbindlist => [
            '1.3.6.1.6.3.1.1.4.1.0', Net::SNMP::OBJECT_IDENTIFIER, '1.3.6.1.4.1.29464.1.1',
            "1.3.6.1.2.1.2.2.1.1.$ifIndex", Net::SNMP::INTEGER, $ifIndex,
            ]
        );
    }
} else {
    pflogger("cannot determine switch port for $mac. Flipping the ports admin status is impossible", 2);
}


exit 1;
# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:

