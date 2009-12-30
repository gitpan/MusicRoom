package MusicRoom;

use warnings;
use strict;

=head1 NAME

MusicRoom - Software for managing digital music

=head1 VERSION

Version 0.40

=cut

our $VERSION = '0.40';


=head1 SYNOPSIS

Managing digital music files can be a complicated business, 
converting between audio formats, ensuring tags are 
consistent and locating extra data like cover art and lyrics.
This package provides a framework for performing these 
tasks.

The package has been designed to simplify the creation of 
a collection of scripts to carry out the essential tasks 
required to manage digital music.  A complete set of sample 
scripts has been distributed with the package.  These can 
be used directly or can be customised to meet your own 
needs.

=head1 NOTES

Much of the work perfomed by the package is implemented using 
other Perl modules and freely available programs.

Extensively tested on Windows, all the facilities should 
function under other environments, but there has not yet been 
any attempt to test on other systems.

This version of the system has been tested for many years 
in a single setup.  However it has not been widely tested 
on lots of configurations.  This means it should be treated 
as Beta software for most users.

=head1 OVERVIEW

Managing your own music on computers can be complex.  There are a number 
of available programs that can help with particular tasks like format
conversion or playing music but keeping track of tags and manipulating auditory 
data in a range of computers can become complex, especially when 
music is accessed through a variety of mechanisms like DAAP servers and MP3 
players.

The MusicRoom package acts as the glue to tie together elements for 
manipulating tag data, tracking down lyrics and cover art, converting 
audio formats, keeping CSV duplicates of meta information and copying 
music files from place to place.

This is an initial version of the package, it has been extensively 
tested at a single location but has not been widely used in many 
different environments.  If something here does not function how 
you expect it to please tell me about it.

=head2 The Directories

Because the package ties together a number of elements there are three 
directories that must be clearly defined:

=over 4

=item * The 'room' directory

Holds the database of music tags, the list of valid artists and song names 
and directories of any lyric files or cover art

=item * The 'tools' directory

Holds the external programs to manipulate audio data (such as C<lame> to encode 
as C<mp3> and C<normalize> to adjust audio volume)

=item * The 'scripts' directory

Holds the Perl scripts that use the MusicRoom package.

=back

=head2 The Enabling Scripts

Included in the release are a number of scripts that use the MusicRoom package 
to perform various tasks.  Some of these can be considered as essential elements
that perform key tasks, like setting up an inital directory structure, others 
should best be thought of as "sample implementations" showing how the package 
can be used.

All scripts have been tested under Windows and most have also been tested on 
Linux.  There should not be anything that is OS specific in this software.

=over 4

=item * C<mr_setup.pl>

This script will ask a set of questions, configure the system and create the 
required database files.

=item * C<mr_list_music.pl>

Scans a directory tree looking for music files and lists them in a CSV file.
The output file is deliberately structured to allow the fix_tags.pl script
to work on it.

Typically the process of importing music requires three steps: 
scanning a source; fixing the meta data; importing the data.  This 
script performs the first of these, identifying files of various audio 
formats, extracting as many tags as it can find and reporting 
what was found in a file that can be easily edited.

=item * C<mr_fix_tags.pl>

Scan a CSV file that holds tags for a set of music files, check where the 
tags need to be corrected and provide some automated tools to apply the 
corrections.  The idea is that once this script is happy with a set of 
tags they are ready to add to the music collection.

This script is just about usable but by no means complete.

=item * C<mr_publish.pl>

Perform the tasks required to take a validated set of tags in a CSV file 
(usually generated by renaming a C<fix_tags> file with C<final>).

This script automates the steps required to add music into the library.
It checks that the suggested tags meet all the restrictions (artist is 
known, year is valid, cover art exists and so on), it then copies the 
original files into the "best" directory, converts the format, normalises 
the volume, adds all the tags and places a standard vesrion in the 
"active" music directory.

=item * C<mr_resample.pl>

Every so often there are significant errors in the tags.  This script 
will regenerate "active" music files based on the latest set of tags.
It uses the "best" data as its source.

The script relies on the bad active files and the entries in the 
"active list" having been removed.  It identifies which entries are 
missing, locates the associated "best" auidio files and publishes 
them to the active directory.

=item * C<mr_search_lyrics.pl>

List all the audio files that have a particular word in 
their lyrics.

=item * C<mr_list_covers.pl>

List where the cover art files are to be found for music 
in the collection.

=item * C<mr_list_lyrics.pl>

List where the lyric files are to be found for music 
in the "active set".  Produces a CSV file listing the 
location of the text files that contain the lyrics.

=item * C<mr_lyric_fetch.pl>

Scan a file of music that needs to have lyrics fetched 
and uses a Perl module to download the appropriate 
lyrics (if it can find them).

The file used is essentially the lines identifying 
missing lyrics from the C<mr_list_lyrics.pl> script.

It uses C<Lyrics::Fetcher>, so you must 
install that module before attempting to run the script.

=back

=head2 The Modules

There are a number of modules that the package is built on:

=over 4

=item * MusicRoom::LogicalModel

Define the logical data structure that can be used to explore the information.

=item * MusicRoom::Album, MusicRoom::Artist, MusicRoom::Track, MusicRoom::Song, MusicRoom::Zone

These modules implement objects that come from the music database.

=item * MusicRoom::Charts

Routines for handling music charts

=item * MusicRoom::CoverArt

Routines for locating and attaching cover art for songs

=item * MusicRoom::Lyrics

Routines for locating and attaching cover art for songs

=item * MusicRoom::File

Handling files of various types, for example converting between audio 
formats

=item * MusicRoom::Date

Handling dates, includes the ability to handle dates before the 1750s

=item * MusicRoom::STN

Generating and using random identifiers for elements such as items and 
file names

=item * MusicRoom::Context

Handles the grouping of variables, and associated values

=item * MusicRoom::Locate

Using location specifiers in combination with songs (and similar things) to
identify associated files (containing for example cover art and lyrics).

=item * MusicRoom::Text::CSV

Handle comma seperated value files.  Should be replaced by the real 
Text::CSV package one day

=item * MusicRoom::Text::Nearest

Find the closest match for a name to a list of valid values

=item * MusicRoom::Text::SoundexNG

A specially tuned Soundex variant that identifies names close to 
a given one

=item * MusicRoom::InitialLists

Some initial lists of valid artists, song titles and albums

=item * MusicRoom::ValidAlbums, MusicRoom::ValidArtists, MusicRoom::ValidSongs

Process the valid names lists

=back

=head1 SUBROUTINES/METHODS

=cut

use Carp;
use Cwd;
use IO::File;
use DBI;

my($phase,%config,$dir,$conf_file);
my(%databases);

use constant MUSICROOM_DIR => "MUSICROOM_DIR";
use constant MUSICROOM_CONF => "musicroom.conf";
use constant MUSICROOM_VERSION => "0.01";

# This would turn on tracing in the DBI code
# DBI->trace(2);

$phase = "configure";
read_conf();

# All these need the configuration to be loaded first, so they 
# have to be "required" after the read_conf()
require MusicRoom::File;
require MusicRoom::Date;
require MusicRoom::LogicalModel;
require MusicRoom::Text::CSV;
require MusicRoom::Text::Nearest;
require MusicRoom::STN;
require MusicRoom::CoverArt;
require MusicRoom::Lyrics;
require MusicRoom::Charts;

sub is_running
  {
    return "" if($phase eq "configure");
    return 1;
  }

sub check_ready
  {
    if($phase eq "configure")
      {
        croak("Must configure MusicRoom before using it, run setup.pl");
      }
    if($phase ne "active")
      {
        croak("Phase has bad value in MusicRoom");
      }
  }

sub read_conf
  {
    # We can only call this once
    if($phase ne "configure")
      {
        carp("Can only call MusicRoom::init() at startup");
        return;
      }

    croak("Must set environment variable MUSICROOM_DIR to use MusicRoom")
                                            if(!defined $ENV{MUSICROOM_DIR});

    $dir = $ENV{MUSICROOM_DIR};

    # If we are on Windows then switch over to using / not \
    $dir =~ s/\\/\//g;

    $dir .= "/" if(!($dir =~ m#/$#));
    $conf_file = $dir.MUSICROOM_CONF;

    # If the configuration file has not yet been created we must 
    # wait for it to be set up
    return if(!-r $conf_file);

    # Read values into the config hash
    my $fh = IO::File->new($conf_file);
    croak("Cannot read $config{config_file}\n") 
                                                    if(!defined $fh);
    my $got_version = "";

    while(my $line = <$fh>)
      {
        chomp $line;
        $line =~ s/\cZ//g;
        next if($line =~ /^\s*$/);
        next if($line =~ /^\s*#/);
        if($line =~ /^\s*(version)\s*\=\s*\"([^\"]*)\"/)
          {
            $config{version} = $2;
            $got_version = 1;
            croak("Configuration is for wrong version ($config{version} not ".
                      MUSICROOM_VERSION.")") if($config{version} ne MUSICROOM_VERSION);
          }
        if($line =~ /^\s*(\w+)\s*\=\s*\"([^\"]*)\"/)
          {
            $config{$1} = $2;
          }
        elsif($line =~ /^\s*(\w+)\s*\=\s*\'([^\']*)\'/)
          {
            $config{$1} = $2;
          }
        elsif($line =~ /^\s*(\w+)\s*\=\s*\|([^\|]*)\|/)
          {
            $config{$1} = $2;
          }
        elsif($line =~ /^\s*(\w+)\s*\=\s*\/([^\/]*)\//)
          {
            $config{$1} = $2;
          }
        elsif($line =~ /^\s*(\w+)\s*\=\s*(\S.+)/)
          {
            $config{$1} = $2;
          }
        else
          {
            carp("Cannot parse config file \"$line\"");
          }
      }
    $fh->close();

    croak("Missing version spec in file")
                                 if(!$got_version);
    open_database("core");
    $phase = "active";
  }

sub configure
  {
    # This is where we store the config, the values set here are the ones 
    # we need to get to the config file
    croak("The MusicRoom system is already configured")
                             if($phase ne "configure");

    croak("Cannot find directory $dir (from \$MUSICROOM_DIR)")
                             if(!-d $dir);

    croak("Do not have permission to write to $dir")
                             if(!-w $dir);

    croak("File $conf_file already exists")
                             if(-r $conf_file);

    my %config_vars =
      (
        # Setting a default_value and read_only is a good way 
        # to nail a config var value
        version => 
          {
            default_value => MUSICROOM_VERSION,
          },
        data_location_file => 
          {
            default_value => ".musicroom_dir",
          },
        db_type =>  
          {
            default_value => "SQLite",
          },
        core_db_name =>  
          {
            default_value => "mrm_core.dat",
          },
        coverart_subdir =>
          {
            default_value => "art",
          },
        lyrics_subdir =>
          {
            default_value => "lyrics",
          },
        tools_dir =>  
          {
            configure => \&configure_var,
            name => "Path to directory containing format conversion tools",
            after_set_fun => sub
              {
                # Convert to absolute path if it was relative
              },
          },
        room_name =>  
          {
            configure => \&configure_var,
            name => "Music Library Name",
            value_type => "text",
          },
        object_file =>
          {
            # Definitions for the database objects
            name => "Object Definition File",
            value_type => "text",
          },
        wav_disabled =>
          {
            default_value => "",
          },
        mp3_disabled =>
          {
            default_value => "",
          },
      );
    
    foreach my $var (keys %config_vars)
      {
        next if(!defined $config_vars{$var}->{default_value});
    
        &{$config_vars{$var}->{before_set_fun}}($var)
                   if(defined $config_vars{$var}->{before_set_fun});
        $config{$var} = $config_vars{$var}->{default_value};
        &{$config_vars{$var}->{after_set_fun}}($var)
                   if(defined $config_vars{$var}->{after_set_fun});
      }

    local($|);

    $|=1;
    my $called_one;
    foreach my $var (sort keys %config_vars)
      {
        if(defined $config_vars{$var}->{configure})
          {
            print "MusicRoom needs to be configured\n"
                                 if(!defined $called_one);
            $called_one = 1;
            &{$config_vars{$var}->{configure}}($var,%config_vars);
          }
      }

    save_conf();
    create_database("core");

    # Now that we are ready to go lets get started
    read_conf();
  }

sub set_conf
  {
    my($var,$val) = @_;

    check_ready();
    # Set and save into the file
    if(!defined $config{$var})
      {
        carp("Cannot set configuration var \"$var\"");
        return undef;
      }

    # Check that the value can be written into the file
    if($val =~ /\"/ && $val =~ /\'/ && $val =~ /\|/ && $val =~ /\//)
      {
        carp("Cannot have <\"> and <\'> and <\|> and <\/> in single conf value");
        $val =~ s/\|/!/g;
      }
    $config{$var} = $val;
    save_conf();
  }

sub get_conf
  {
    my($var,$silent) = @_;
    # Get the value
    check_ready();

    # Magic value to get to the directory
    return $dir
             if(lc($var) eq "dir");

    # Look up in the configuration
    if(!defined $config{$var})
      {
        carp("No value for configuration var \"$var\"") 
                              if(!defined $silent || !$silent);
        return undef;
      }
    return $config{$var};
  }

sub read_config
  {
    croak("Cannot find $conf_file")
                     if(!-r $conf_file);

    # Read values into the config hash
    my $fh = IO::File->new($conf_file);
    croak("Cannot read $conf_file\n") 
                                                    if(!defined $fh);
    while(my $line = <$fh>)
      {
        chomp $line;
        $line =~ s/\cZ//g;
        next if($line =~ /^\s*$/);
        next if($line =~ /^\s*#/);
        if($line =~ /^\s*(\w+)\s*\=\s*\"([^\"]*)\"/)
          {
            $config{$1} = $2;
          }
        elsif($line =~ /^\s*(\w+)\s*\=\s*\'([^\']*)\'/)
          {
            $config{$1} = $2;
          }
        elsif($line =~ /^\s*(\w+)\s*\=\s*\|([^\|]*)\|/)
          {
            $config{$1} = $2;
          }
        elsif($line =~ /^\s*(\w+)\s*\=\s*\/([^\/]*)\//)
          {
            $config{$1} = $2;
          }
        elsif($line =~ /^\s*(\w+)\s*\=\s*(\S.+)/)
          {
            $config{$1} = $2;
          }
        else
          {
            carp("Cannot parse config file \"$line\"");
          }
      }
    $fh->close();
  }

sub save_conf
  {
    my $fh = IO::File->new(">$conf_file");
    if(!defined $fh)
      {
        croak("Cannot write to $conf_file");
      }

    my $date_str = MusicRoom::Date::text(undef);
    print $fh <<"EndHeader";
# Configuration file for MusicRoom
#     Saved: $date_str
#   Program: $0
#
EndHeader
    foreach my $key (sort keys %config)
      {
        my $val = $config{$key};

        if(!($val =~ /\"/))
          {
            print $fh "$key=\"$val\"\n";
          }
        elsif(!($val =~ /\'/))
          {
            print $fh "$key=\'$val\'\n";
          }
        elsif(!($val =~ /\|/))
          {
            print $fh "$key=\|$val\|\n";
          }
        elsif(!($val =~ /\//))
          {
            print $fh "$key=\/$val\/\n";
          }
        else
          {
            carp("Bad setting for $key ($val)");
          }
      }
    $fh->close();
  }

sub configure_var
  {
    my($var,%config_vars) = @_;

    if(!defined $var)
      {
        carp("configure_var called without variable name");
        return;
      }
    elsif(!defined $config_vars{$var})
      {
        carp("Attempt to configure unknown var $var");
        return;
      }
    elsif(!defined $config_vars{$var}->{value_type} ||
                   $config_vars{$var}->{value_type} eq "text")
      {
        my $name = $config_vars{$var}->{name};
        $name = $var if(!defined $name);
        print "Define a value for \"$name\": ";
        my $val = <>;
        chomp $val;
        $config{$var} = $val;
      }
    else
      {
        carp("No method defined for $config_vars{$var}->{value_type} vars yet");
      }
  }

sub open_database
  {
    my($part) = @_;

    my $dbfile = $config{"${part}_db_name"};
    my $dbtype = $config{db_type};

    croak("Cannot find db_name for \"${part}\"")
                              if(!defined $dbfile);

    $databases{$part} = {} if(!defined $databases{$part});
    $databases{$part}->{handle} = DBI->connect(
                          "dbi:$dbtype:$dir/$dbfile", "", "",
                              {RaiseError => 1, AutoCommit => 1});
  }

sub create_database
  {
    # We have to create a database with the appropriate tables in
    my($part) = @_;

    open_database($part);

    foreach my $table (MusicRoom::LogicalModel::list_physical_tables($part))
      {
        my $stmt = "CREATE TABLE \"$table\" ( ";

        my $id;
        foreach my $col (MusicRoom::LogicalModel::get_physical_columns($part,$table))
          {
            $id = "id" if($col eq "id");
            $id = "name" if(!defined $id && $col eq "name");

            my $spec = MusicRoom::LogicalModel::get_physical_column($part,$table,$col);

            $stmt .= "\"$col\" $spec, ";
          }
        croak("Must have an id or name in every table")
                                             if(!defined $id);

        # $stmt =~ s/, $/) /;
        $stmt .= "PRIMARY KEY ( \"$id\" ));";
        my $table = $databases{$part}->{handle}->prepare($stmt);
        if(!defined $table)
          {
            carp("Failed to prepare $stmt");
            next;
          }
        $table->execute();
      }
    # The loading up of data is done in the setup.pl script, if it was 
    # here then the complete initial list of valid items would be loaded
    # into every script that used MusicRoom and that would just be silly

    # But we do need to close the database so that the read_conf can open
    # it again
    shutdown_database($part);
  }

sub select
  {
    # Do an SQL statement 
    my($part,$table,$cols,$where_clause) = @_;

    if(!defined $databases{$part} || 
           !defined $databases{$part}->{handle})
      {
        carp("Must open database \"$part\" before attempting to use it");
        return undef;
      }
    if(ref($cols) ne "ARRAY")
      {
        carp("Must supply an array of column names");
        return undef;
      }
    if($#{$cols} < 0)
      {
        carp("Must supply at least one column to select");
        return undef;
      }

    my $stmt = "SELECT ".join(',',@{$cols})." FROM $table";
    if(defined $where_clause && $where_clause ne "")
      {
        $stmt .= " WHERE ".$where_clause;
      }
    $stmt .= ";";

    my $sth = $databases{$part}->{handle}->prepare($stmt);
    if(!defined $sth)
      {
        carp("Failed to prepare \"$stmt\"");
        return ();
      }
    my @result;
    my $rows_affected = $sth->execute();

    while(1)
      {
        my $ret = $sth->fetchrow_arrayref();
        return @result if(!defined $ret || ref($ret) ne "ARRAY" || !@{$ret});

        # Need to copy the result, otherwise the next fetchrow_arrayref() will
        # overwrite it
        my @result_arry = @{$ret};
        push @result,\@result_arry;
      }
  }

sub insert
  {
    my($part,$table,$cols,$values) = @_;

    if(!defined $databases{$part} || 
           !defined $databases{$part}->{handle})
      {
        carp("Must open database \"$part\" before attempting to use it");
        return undef;
      }
    if(ref($cols) ne "ARRAY")
      {
        carp("Must supply an array of column names");
        return undef;
      }
    if(ref($values) ne "ARRAY")
      {
        carp("Must supply an array of values");
        return undef;
      }
    if($#{$cols} < 0)
      {
        carp("Must supply at least one column to insert");
        return undef;
      }
    if($#{$cols} != $#{$values})
      {
        carp("Supplied ".($#{$values}+1)." values for ".($#{$cols}+1)." slots");
        return undef;
      }

    my @vals;
    foreach my $val (@{$values})
      {
        push @vals,quoteSQL($part,$val);
      }
    my $stat = "INSERT INTO $table (".join(',',@{$cols}).
                                           ") VALUES (".join(',',@vals).");";

    my $count = $databases{$part}->{handle}->do($stat);
    if($count != 1)
      {
        carp("Got return value of \"$count\" from \"$stat\"");
        return undef;
      }
    return 1;
  }

sub doSQL
  {
    # Do an SQL statement 
    my($part,$stmt) = @_;

    if(!defined $databases{$part} || 
           !defined $databases{$part}->{handle})
      {
        carp("Must open database \"$part\" before attempting to use it");
        return undef;
      }
    return $databases{$part}->{handle}->do($stmt);
  }

sub quoteSQL
  {
    # Convert a string to a form that SQL can manage
    my($part,$string) = @_;

    if(!defined $databases{$part} || 
           !defined $databases{$part}->{handle})
      {
        carp("Must open database \"$part\" before attempting to use it");
        return undef;
      }
    # Special cases
    return "\'".$string."\'"
                   if(lc($string) eq "true" || lc($string) eq "false");


    return $databases{$part}->{handle}->quote($string);
  }

sub shutdown_database
  {
    # Close down database handles
    my($part) = @_;

    if(defined $part)
      {
        $databases{$part}->{handle}->disconnect()
                      if(defined $databases{$part}->{handle});
        $databases{$part}->{handle} = undef;
        return;
      }
    foreach my $each_part (keys %databases)
      {
        shutdown_database($each_part);
      }
  }

=head1 AUTHOR

Steve Hawtin, C<< <steve at tsort.demon.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-musicroom at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MusicRoom>.  I will be 
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MusicRoom

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MusicRoom>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MusicRoom>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MusicRoom>

=item * Search CPAN

L<http://search.cpan.org/dist/MusicRoom/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2007-2010 Steve Hawtin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of MusicRoom