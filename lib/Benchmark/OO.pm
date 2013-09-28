package Benchmark::OO;
use strict;
use warnings;
use Time::HiRes qw(gettimeofday);

our $VERSION = '0.02';

sub start {
    my $class = shift;
    my $self = {};
    $self->{RECORD}->{PAUSECOUNT} = 0;
    $self->{RECORD}->{RESUMECOUNT} = 0;
    ($self->{RECORD}->{START_SEC}, $self->{RECORD}->{START_MICROSEC}) = gettimeofday();
    return bless $self, $class;
}


sub stop {
    my $self = shift;
    ($self->{RECORD}->{END_SEC}, $self->{RECORD}->{END_MICROSEC}) = gettimeofday();
}

sub pause {
    my $self = shift;
    my $pause_count = $self->{RECORD}->{PAUSECOUNT}++;
    ($self->{RECORD}->{'PAUSE'.$pause_count}->{START_SEC}, $self->{RECORD}->{'PAUSE'.$pause_count}->{START_MICROSEC}) = gettimeofday();
}

sub resume {
    my $self = shift;
    my $resume_count = $self->{RECORD}->{RESUMECOUNT}++;
    ($self->{RECORD}->{'RESUME'.$resume_count}->{START_SEC}, $self->{RECORD}->{'RESUME'.$resume_count}->{START_MICROSEC}) = gettimeofday();
}

sub _add_fields {
    my $self = shift;
    #Forcing to use stop function
    unless (defined($self->{RECORD}->{END_SEC}) || defined($self->{RECORD}->{END_MICROSEC})) {
        die "Must call stop function to stop bench-marking.";
    }
    
    
    #Calculating Start and End Datetime in genaral format
    my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
    my ($sec, $min, $hour, $day, $month, $year) = (localtime($self->{RECORD}->{START_SEC}))[0,1,2,3,4,5];
    $year = $year+1900;
    $hour =~ s/\b(\d)\b/0$1/;
    $min =~ s/\b(\d)\b/0$1/;
    $sec =~ s/\b(\d)\b/0$1/;
    $self->{RECORD}->{START_DATETIME} = qq($months[$month] $day $year $hour:$min:$sec);
    ($sec, $min, $hour, $day, $month, $year) = (localtime($self->{RECORD}->{END_SEC}))[0,1,2,3,4,5];
    $year = $year+1900;
    $hour =~ s/\b(\d)\b/0$1/;
    $min =~ s/\b(\d)\b/0$1/;
    $sec =~ s/\b(\d)\b/0$1/;
    $self->{RECORD}->{END_DATETIME} = qq($months[$month] $day $year $hour:$min:$sec);
    
    
    my ($total_pause_microsecs);
    #if pause done in between
    if (defined($self->{RECORD}->{PAUSE0}->{START_SEC})) {
        #Initiating calcluation
        $total_pause_microsecs = (($self->{RECORD}->{"PAUSE0"}->{START_SEC} * 1000000) + $self->{RECORD}->{"PAUSE0"}->{START_MICROSEC}) - (($self->{RECORD}->{START_SEC} * 1000000) + $self->{RECORD}->{START_MICROSEC});
        
        #In between calculation
        my $i;
        for($i = 0; $i < $self->{RECORD}->{RESUMECOUNT}; $i++) {
            if (defined($self->{RECORD}->{'RESUME'.$i}->{START_SEC}) && defined($self->{RECORD}->{'RESUME'.$i}->{START_MICROSEC}) && defined($self->{RECORD}->{'PAUSE'.($i+1)}->{START_SEC}) && defined($self->{RECORD}->{'PAUSE'.($i+1)}->{START_MICROSEC})) {
                $total_pause_microsecs += ((($self->{RECORD}->{'PAUSE'.($i+1)}->{START_SEC} * 1000000) + $self->{RECORD}->{'PAUSE'.($i+1)}->{START_MICROSEC}) - (($self->{RECORD}->{'RESUME'.$i}->{START_SEC} * 1000000) + $self->{RECORD}->{'RESUME'.$i}->{START_MICROSEC}));
            }
        }
            
        #Ending calculation    
        if (defined($self->{RECORD}->{'RESUME'.($i-1)}->{START_SEC}) && defined($self->{RECORD}->{'RESUME'.($i-1)}->{START_MICROSEC})) {
            $total_pause_microsecs += ((($self->{RECORD}->{END_SEC} * 1000000) + $self->{RECORD}->{END_MICROSEC}) - (($self->{RECORD}->{'RESUME'.($i-1)}->{START_SEC} * 1000000) + $self->{RECORD}->{'RESUME'.($i-1)}->{START_MICROSEC}));
        }
    } else {
        #If no pause in between
        $total_pause_microsecs = ($self->{RECORD}->{END_SEC} * 1000000 + $self->{RECORD}->{END_MICROSEC} - $self->{RECORD}->{START_SEC} * 1000000 + $self->{RECORD}->{START_MICROSEC});
    }
    
    #Total consumed seconds and microseconds
    $self->{RECORD}->{TAKEN_SEC} = sprintf("%d", ($total_pause_microsecs) / 1000000);
    $self->{RECORD}->{TAKEN_MICROSEC} = ($total_pause_microsecs) % 1000000;
}

#Print benchmark in tablur form
sub print_benchmark {
    my $self = shift;
    _add_fields($self);
    
    print qq(Start Datetime: $self->{RECORD}->{START_DATETIME}\n);
    print qq(End Datetime: $self->{RECORD}->{END_DATETIME}\n);
    
    printf("%-20s%20s%20s%25s\n", "Iteration", "Second", "Microsecond", "Total in Microseconds");
    printf("===========================================================================================\n");
    printf("%-20s%20d%20d%25d\n", "START", $self->{RECORD}->{START_SEC}, $self->{RECORD}->{START_MICROSEC}, ($self->{RECORD}->{START_SEC} * 1000000 + $self->{RECORD}->{START_MICROSEC}));

    my $bigger = ($self->{RECORD}->{RESUMECOUNT} > $self->{RECORD}->{PAUSECOUNT})? $self->{RECORD}->{RESUMECOUNT}: $self->{RECORD}->{PAUSECOUNT};
    
    for(my $i = 0; $i < $bigger; $i++) {
        if (defined($self->{RECORD}->{'PAUSE'.$i}->{START_SEC}) && defined($self->{RECORD}->{'PAUSE'.$i}->{START_MICROSEC})) {
            printf("%-20s%20d%20d%25d\n", "PAUSE$i", $self->{RECORD}->{'PAUSE'.$i}->{START_SEC}, $self->{RECORD}->{'PAUSE'.$i}->{START_MICROSEC}, ($self->{RECORD}->{'PAUSE'.$i}->{START_SEC} * 1000000 + $self->{RECORD}->{'PAUSE'.$i}->{START_MICROSEC}));
        }
        
        if (defined($self->{RECORD}->{'RESUME'.$i}->{START_SEC}) && defined($self->{RECORD}->{'RESUME'.$i}->{START_MICROSEC})) {
            printf("%-20s%20d%20d%25d\n", "RESUME$i", $self->{RECORD}->{'RESUME'.$i}->{START_SEC}, $self->{RECORD}->{'RESUME'.$i}->{START_MICROSEC}, ($self->{RECORD}->{'RESUME'.$i}->{START_SEC} * 1000000 + $self->{RECORD}->{'RESUME'.$i}->{START_MICROSEC}));
        }
    }
    
    printf("%-20s%20d%20d%25d\n", "END", $self->{RECORD}->{END_SEC}, $self->{RECORD}->{END_MICROSEC}, ($self->{RECORD}->{END_SEC} * 1000000 + $self->{RECORD}->{END_MICROSEC}));
    printf("===========================================================================================\n");
    print qq(Total time taken: $self->{RECORD}->{TAKEN_SEC} seconds );
    print qq($self->{RECORD}->{TAKEN_MICROSEC} microseconds\n);
}

#Return data structure of benchmark
sub get_benchmark {
    my $self = shift;
    _add_fields($self);
    
    return $self->{RECORD};
}


1;


__END__

=head1 NAME

Benchmark::OO - Simple interface to do benchmarking.

=head1 SYNOPSIS

    use Benchmark::OO;

    print "Benchmarking for loop runs 2000 times.\n";
    #Sart benchmarking here
    my $obj = Benchmark::OO->start();
    
    for(my $i = 0; $i < 2000; $i++) {
    }
    
    #First pause
    $obj->pause();
    
    print "Benchmarking for loop runs 1000 times.\n";
    #First resume
    $obj->resume();
    
    for(my $i = 0; $i < 1000; $i++) {
    }
    
    #Second pause
    $obj->pause();
    
    print "Benchmarking for loop runs 500 times.\n";
    #Second resume
    $obj->resume();
    
    for(my $i = 0; $i < 1000; $i++) {
    }
    
    #Final stop of benchmarking
    $obj->stop();
    
    #Print total result in tabluar form
    $obj->print_benchmark();
    
    #Get benchmark result on return hash form
    my $ret = $obj->get_benchmark();
    require Data::Dumper;
    print Data::Dumper::Dumper($ret);


=head1 DESCRIPTION

This is a simple benchmarking module, can be used to get the banchmark at any part of code or complete code.

There are four functions (start(it is also constructor), pause, resume, stop) in this module to perform benchmarking. It is recommended to use these functions in logical order. otherwise total benchmarking result will be having incorrect value.

There are two fundtions, (print_benchmark and get_benchmark) to get result of benchmark.

=over 4


=item start

This function will start benchmarking.

=item pause

This function will pause benchmarking. Should be called after start or resume.

=item resume

This function will resume benchmarking, which was paused earlier using pause() function. Should be called after pause.

=item stop

This function will stop benchmarking. Should be called after start or resume.


=item print_benchmark

This function will print benchmark result in tablur form. Below is example:
    
    Start Datetime: Sep 28 2013 21:57:06
    End Datetime: Sep 28 2013 21:57:06
    Iteration                         Second         Microsecond    Total in Microseconds
    ===========================================================================================
    START                         1380385626              561582         1380385626561582
    PAUSE0                        1380385626              562029         1380385626562029
    RESUME0                       1380385626              562058         1380385626562058
    PAUSE1                        1380385626              562274         1380385626562274
    RESUME1                       1380385626              562290         1380385626562290
    END                           1380385626              562520         1380385626562520
    ===========================================================================================
    Total time taken: 0 seconds 893 microseconds


=item get_benchmark

This function will return anonymous hash reference of benchmark result. Below is an example:

    {
      'START_DATETIME' => 'Sep 28 2013 21:57:06',
      'PAUSECOUNT' => 2,
      'TAKEN_MICROSEC' => 893,
      'PAUSE2' => {},
      'RESUMECOUNT' => 2,
      'END_MICROSEC' => 562520,
      'RESUME0' => {
                     'START_SEC' => 1380385626,
                     'START_MICROSEC' => 562058
                   },
      'PAUSE0' => {
                    'START_SEC' => 1380385626,
                    'START_MICROSEC' => 562029
                  },
      'END_SEC' => 1380385626,
      'TAKEN_SEC' => '0',
      'END_DATETIME' => 'Sep 28 2013 21:57:06',
      'START_SEC' => 1380385626,
      'PAUSE1' => {
                    'START_SEC' => 1380385626,
                    'START_MICROSEC' => 562274
                  },
      'RESUME1' => {
                     'START_SEC' => 1380385626,
                     'START_MICROSEC' => 562290
                   },
      'START_MICROSEC' => 561582
    };



=back


=head1 AUTHOR

Vipin Singh, E<lt>qwer@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Vipin Singh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
