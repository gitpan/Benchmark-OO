package Benchmark::OO;
use strict;
use warnings;
use Time::HiRes qw(gettimeofday);

our $VERSION = '0.01';

sub start {
    my $class = shift;
    my $self = {};
    ($self->{RECORD}->{START_SEC}, $self->{RECORD}->{START_MICROSEC}) = gettimeofday();
    return bless $self, $class;
}


sub stop {
    my $self = shift;
    ($self->{RECORD}->{END_SEC}, $self->{RECORD}->{END_MICROSEC}) = gettimeofday();
}

sub _add_fields {
    my $self = shift;
    
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
    
    
    my $start_total_microsec = $self->{RECORD}->{START_SEC} * 1000000 + $self->{RECORD}->{START_MICROSEC};
    my $end_total_microsec = ($self->{RECORD}->{END_SEC} * 1000000) + $self->{RECORD}->{END_MICROSEC};
    $self->{RECORD}->{TAKEN_SEC} = sprintf("%d", ($end_total_microsec - $start_total_microsec) / 1000000);
    $self->{RECORD}->{TAKEN_MICROSEC} = ($end_total_microsec - $start_total_microsec) % 1000000;
}

sub print_benchmark {
    my $self = shift;
    _add_fields($self);
    
    print qq(Start Datetime: $self->{RECORD}->{START_DATETIME}\n);
    print qq(Start second epoch: $self->{RECORD}->{START_SEC}\n);
    print qq(Start Microsecond epoch: $self->{RECORD}->{START_MICROSEC}\n);
    print qq(End Datetime: $self->{RECORD}->{END_DATETIME}\n);
    print qq(End second epoch: $self->{RECORD}->{END_SEC}\n);
    print qq(End Mocrosecond epoch: $self->{RECORD}->{END_MICROSEC}\n);
    print qq(Total time taken: $self->{RECORD}->{TAKEN_SEC} seconds );
    print qq($self->{RECORD}->{TAKEN_MICROSEC} microseconds\n);
}

sub get_benchmark {
    my $self = shift;
    _add_fields($self);
    
    return $self->{RECORD};
}

1;


__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Benchmark::OO - Simple interface to do benchmarking.

=head1 SYNOPSIS

    use Benchmark::OO;

    #Start benchmarking here
    my $obj = Benchmark::OO->start();
    
    for(my $i = 0; $i < 20000000; $i++) {
        
    }
    
    #Stop benchmarking here
    $obj->stop();
    
    #To print benchmark
    $obj->print_benchmark();
    
    #To get benchmark hash reference
    my $ret = $obj->get_benchmark();
    require Data::Dumper;
    print Data::Dumper::Dumper($ret);


=head1 DESCRIPTION

This is a simple benchmarking module, can be used to get the banchmark any part of code or complete code.

=over 4


=item start

This function will start benchmarking.


=item stop

This function will stop benchmarking.


=item print_benchmark

This function will print benchmark result. Below is example:
    
    Start Datetime: Sep 21 2013 22:37:39
    Start second epoch: 1379783259
    Start Microsecond epoch: 735328
    End Datetime: Sep 21 2013 22:37:42
    End second epoch: 1379783262
    End Mocrosecond epoch: 755713
    Total time taken: 3 seconds 20385 microseconds


=item stop

This function will return anonymous hash reference of benchmark result. Below is an example:

    {
        'START_DATETIME' => 'Sep 21 2013 22:37:39',
        'TAKEN_MICROSEC' => 20385,
        'END_MICROSEC' => 755713,
        'END_SEC' => 1379783262,
        'START_SEC' => 1379783259,
        'END_DATETIME' => 'Sep 21 2013 22:37:42',
        'TAKEN_SEC' => '3',
        'START_MICROSEC' => 735328
    }



=back


=head1 AUTHOR

Vipin Singh, E<lt>qwer@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Vipin Singh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
