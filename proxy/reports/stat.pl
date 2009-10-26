#!/usr/bin/perl
use strict; use warnings; use Fatal;
use POSIX;

my $server = shift;
my $timestamp = shift;

$ENV{TZ} = 'US/Central';

my %d = (); # Total messages
my %i = (); # INVITEs
my %t = (); # INVITEs with 503
my $min;
my $max;
our %call;

our %stats = ();

while(<>)
{
  chomp;
  my @d = split(/\|/);

  # Set variables
  my $s = $d[6];
  ## warn($_), 
  next unless defined $s;

  my $hour = localtime(int($s/3600)*3600);
  $stats{"messages ^ $hour"}++;

  my $uniq_id = $d[3];
  my $method = $d[0];

  # Start processing
  $stats{"messages * $d[10]"}++;

  # Select targets
  if(1)
  {
    $stats{'messages_used'}++;
  }
  else
  {
    $stats{'messages_ignored'}++,
    next;
  }

  my $account = $d[14]||$d[15]||'?';
  $stats{"messages \@ $account ^ $hour"}++;
  $stats{"messages < $d[11] ^ $hour"}++; # src
  $stats{"messages > $d[10] ^ $hour"}++; # dst

  $d{$s}++;
  $i{$s}++ if $method eq 'INVITE' and $d[4] >= 200;

  $stats{'messages'} ++;

  $stats{"method $method"}++;
  $stats{"method $method ^ $hour"}++;
  $stats{"method INVITE $d[4]"}++,
  $stats{"method INVITE $d[4] ^ $hour"}++ if $method eq 'INVITE';

  # We collect the earliest call start in order to compute
  # the number of concurrent call paths.
  # This is different from billing where we would use the 200
  # as the start time.
  my $set_start = sub {
    $stats{start}++;
    return
      if exists $call{$uniq_id}
      && defined $call{$uniq_id}->{start} 
      && $call{$uniq_id}->{start} < $s;

    $stats{start_ok}++,
    $call{$uniq_id}->{start} = $s;
    $call{$uniq_id}->{src} = $d[11];
    $call{$uniq_id}->{dst} = $d[10];
  };

  $set_start->()
    if $method eq 'INVITE' and grep { $d[4] eq $_ } ('200','183','180');

  $call{$uniq_id}->{connect} = $s,
  $call{$uniq_id}->{account} = $account
    if $method eq 'INVITE' and $d[4] eq '200';

  $stats{end}++,
  $call{$uniq_id}->{end} = $s
    if ($method eq 'BYE' || $method eq 'CANCEL');

  $stats{"503 \@ $account ^ $hour"}++,
  $stats{"target_503 $d[10] ^ $hour"}++,
  $t{$s}++
    if $method eq 'INVITE' and $d[4] eq '503';
  $min = $s if not defined $min;
  $min = $s if $s < $min;
  $max = $s if not defined $max;
  $max = $s if $s > $max;
}

# Flatten the calls statistics

my %callpaths;
my %callpaths_src;
my %callpaths_dst;
my %call_count = ();
for my $uniq_id (keys %call)
{
  my $src = $call{$uniq_id}->{src};
  my $dst = $call{$uniq_id}->{dst};
  if( exists $call{$uniq_id}->{connect} and exists $call{$uniq_id}->{end} )
  {
     my $hour = localtime(int($call{$uniq_id}->{connect}/3600)*3600);
     my $duration = $call{$uniq_id}->{end} - $call{$uniq_id}->{connect};
     $duration = POSIX::floor(0.5+$duration/6.0)/10.0;
     my $account = $call{$uniq_id}->{account};
     $duration = 0 if $duration < 0;
     $stats{"callpaths_duration"} += $duration;
     $stats{"callpaths_duration ^ $hour"} += $duration;
     $stats{"callpaths_duration \@ $account ^ $hour"} += $duration;
     $stats{"callpaths_duration < $src ^ $hour"} += $duration;
     $stats{"callpaths_duration > $dst ^ $hour"} += $duration;
  }

  if( exists $call{$uniq_id}->{start} and exists $call{$uniq_id}->{end} )
  {
    for my $s ($call{$uniq_id}->{start} .. $call{$uniq_id}->{end})
    {
      $callpaths{$s}++;
      $callpaths_src{$src}->{$s}++;
      $callpaths_src{$dst}->{$s}++;
    }
    delete $call{$uniq_id};
  }
}

for my $s ($min..$max)
{
  my $hour = localtime(int($s/3600)*3600);

  my $max_ = sub {
    my ($name,$v) = @_;

    $v ||= 0;

    my $n1 = "max_${name}";
    $stats{$n1} = $v if !exists $stats{$n1};

    my $n2 = "$n1 at";
    $stats{$n2} = $s if !exists $stats{$n2};

    my $n3 = "$n1 ^ $hour";
    $stats{$n3} = $v if !exists $stats{$n3};

    if( $v > $stats{$n1} )
    {
      $stats{$n1} = $v;
      $stats{$n2} = $s;
      $stats{$n3} = $v;
    }
  };

  # Messages
  $max_->(q(messages),$d{$s});

  # INVITEs
  $max_->(q(invite),$i{$s});

  # 503s
  $max_->(q(503),$t{$s});

  # Callpaths
  $max_->(q(callpaths),$callpaths{$s});

  # Callpaths per source
  for my $src (keys %callpaths_src)
  {
    $max_->("callpaths < $src",$callpaths_src{$src}->{$s});
    $max_->("callpaths > $src",$callpaths_src{$src}->{$s});
  }
}

for my $k (sort keys %stats)
{
  print join("\t",$k,$stats{$k})."\n";
}
 
