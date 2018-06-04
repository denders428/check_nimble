#!/usr/bin/perl


use strict;
use warnings;

use Monitoring::Plugin;
use REST::Client;
use JSON;

use LWP::UserAgent;
use Net::SSL;
use IO::Socket::SSL;
use Data::Dumper;



my $np = Monitoring::Plugin->new( 
	shortname => "nimble_powersupply",
	usage => "Usage: %s [-H] <management ip of Array> [-user] nimble api user [-pass] nimble api user password -l [left,right] [-v] ",
	 );

$np->add_arg(
	spec => "host|H=s",
	help => "-H, --host=STRING. Hostname or ip address of the nimble Array API",
	required => 1,
	);

$np->add_arg(
	spec => "user|u=s",
	help => "-u, --user=STRING. User name for the API authorized user",
	required => 1,
	);

$np->add_arg(
	spec => "pass|p=s",
	help => "-p, --pass=STRING. Password for the API management user",
	required => 1,
	);

$np->add_arg(
	spec => "location|l=s",
	help => "-l, --location=place.identify which power power supply to test either <left,right>",
	required => 1,
	);

$np->getopts;

##############################################
# Setup the AP connection
##############################################
    my ($login_cred);
 
    $ENV{HTTPS_CA_FILE} = 'C:\gitrepo\Nimble\YEGSN05MGCLOCAL.crt';
 
    my $client = REST::Client->new( ca => 'C:\gitrepo\Nimble\YEGSN05MGCLOCAL.crt' );
 
    $client->setHost( "https://".$np->opts->host.":5392/v1/");
 
    $login_cred->{"data"}->{"username"} = $np->opts->user;
    $login_cred->{"data"}->{"password"} = $np->opts->pass;
 
    $login_cred = encode_json $login_cred;
 
    $client->request( "POST", "tokens", $login_cred );
 
    die "Failed to connect: $!\n" . $client->responseContent()
      if $client->responseContent() =~ /t connect/;
 
    my $tokenObj = decode_json $client->responseContent();
 
    my $token   = $tokenObj->{"data"}->{"session_token"};
    my $tokenId = $tokenObj->{"data"}->{"id"};
 
    $client->addHeader( "X-Auth-Token", $token );

############################################
# Shelf read
############################################

    my $opts;
    $opts->{data} = {  };
    $opts = encode_json $opts;
 
    $client->request( "GET", "shelves/detail", $opts );
 
    my $out = decode_json $client->responseContent();
 
    my @chassis_sensors = @{$out->{'data'}[0]->{'chassis_sensors'}};
    #print "\nOutput is :\n\n ". Data::Dumper->Dump([\@chassis_sensors], [*array, *hash, *mdarray]) ;
    my $sensorArrayLth = scalar @chassis_sensors ;
	
	for (my $i = 0 ;$i <= $sensorArrayLth; $i++ ) {
      if ($chassis_sensors[$i]{location} eq 'right rear') {
        if($chassis_sensors[$i]{status} eq 'OK') {
          $np->plugin_exit(
          return_code => 0,
          message => $chassis_sensors[$i]{location}.' power supply is OK',
          );
        }
        else {
          $np->plugin_exit(
          return_code => 2,
          message => $np->{'opts'}->{'location'}.' power supply has failed',
          );
        }
      }
      elsif ($chassis_sensors[$i]{location} eq 'left rear') {
        if($chassis_sensors[$i]{status} eq 'OK') {
          $np->plugin_exit(
          return_code => 0,
          message => $chassis_sensors[$i]{location}.' power supply is OK',
          );
        }
        else {
          $np->plugin_exit(
          return_code => 2,
          message => $np->{'opts'}->{'location'}.' power supply has failed',
          );
        }
      }
    };
