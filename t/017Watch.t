#testing init_and_watch

use Test::More;

use warnings;
use strict;

use Log::Log4perl;
use File::Spec;

my $WORK_DIR = "tmp";
if(-d "t") {
    $WORK_DIR = File::Spec->catfile(qw(t tmp));
}

unless (-e "$WORK_DIR"){
    mkdir("$WORK_DIR", 0755) || die "can't create $WORK_DIR ($!)";
}

my $testfile = File::Spec->catfile($WORK_DIR, "test17.log");
unlink $testfile if (-e $testfile);

my $testconf = File::Spec->catfile($WORK_DIR, "test17.conf");
unlink $testconf if (-e $testconf);

my $conf1 = <<EOL;
log4j.category.animal.dog   = INFO, myAppender

log4j.appender.myAppender          = Log::Log4perl::Appender::File
log4j.appender.myAppender.layout   = Log::Log4perl::Layout::SimpleLayout
log4j.appender.myAppender.filename = $testfile
log4j.appender.myAppender.mode     = append

EOL
open (CONF, ">$testconf") || die "can't open $testconf $!";
print CONF $conf1;
close CONF;


Log::Log4perl->init_and_watch($testconf, 2);

my $logger = Log::Log4perl::get_logger('animal.dog');

$logger->debug('debug message');
$logger->info('info message');

ok(! $logger->is_debug(), "is_debug - true");
ok(  $logger->is_info(),  "is_info - true");
ok(  $logger->is_warn(),  "is_warn - true");
ok(  $logger->is_error(), "is_error - true");
ok(  $logger->is_fatal(), "is_fatal - true");

# ***************************************************************
# do it again

print "sleeping for 3 secs\n";
sleep 3;

my $conf2 = <<EOL;
log4j.category.animal.dog   = DEBUG, myAppender

log4j.appender.myAppender          = Log::Log4perl::Appender::File
log4j.appender.myAppender.layout = org.apache.log4j.PatternLayout
log4j.appender.myAppender.layout.ConversionPattern=%-5p %c - %m%n

log4j.appender.myAppender.filename = $testfile
log4j.appender.myAppender.mode     = append
EOL

open (CONF, ">$testconf") || die "can't open $testconf $!";
print CONF $conf2;
close CONF;

$logger = Log::Log4perl::get_logger('animal.dog');

$logger->debug('2nd debug message');
$logger->info('2nd info message');
print "sleeping for 3 secs\n";
sleep 3;
$logger->info('2nd info message again');

open (LOG, $testfile) or die "can't open $testfile $!";
my @log = <LOG>;
close LOG;
my $log = join('',@log);

is($log, "INFO - info message\nDEBUG animal.dog - 2nd debug message\nINFO  animal.dog - 2nd info message\nINFO  animal.dog - 2nd info message again\n", "1st init");
ok(  $logger->is_debug(), "is_debug - false");
ok(  $logger->is_info(),  "is_info - true");
ok(  $logger->is_warn(),  "is_warn - true");
ok(  $logger->is_error(), "is_error - true");
ok(  $logger->is_fatal(), "is_fatal - true");

# ***************************************************************
# do it 3rd time

print "sleeping for 3 secs\n";
sleep 3;

$conf2 = <<EOL;
log4j.category.animal.dog   = INFO, myAppender

log4j.appender.myAppender          = Log::Log4perl::Appender::File
log4j.appender.myAppender.layout   = Log::Log4perl::Layout::SimpleLayout
log4j.appender.myAppender.filename = $testfile
log4j.appender.myAppender.mode     = append
EOL
open (CONF, ">$testconf") || die "can't open $testconf $!";
print CONF $conf2;
close CONF;

$logger = Log::Log4perl::get_logger('animal.dog');

$logger->debug('2nd debug message');
$logger->info('3rd info message');

ok(! $logger->is_debug(), "is_debug - false");
ok(  $logger->is_info(),  "is_info - true");
ok(  $logger->is_warn(),  "is_warn - true");
ok(  $logger->is_error(), "is_error - true");
ok(  $logger->is_fatal(), "is_fatal - true");

open (LOG, $testfile) or die "can't open $testfile $!";
@log = <LOG>;
close LOG;
$log = join('',@log);

is($log, "INFO - info message\nDEBUG animal.dog - 2nd debug message\nINFO  animal.dog - 2nd info message\nINFO  animal.dog - 2nd info message again\nINFO - 3rd info message\n");

BEGIN {plan tests => 17};

unlink $testfile if (-e $testfile);
unlink $testconf if (-e $testconf);
