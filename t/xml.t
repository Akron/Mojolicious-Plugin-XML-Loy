#!/usr/bin/env perl
use Test::More;
use Test::Mojo;
use strict;
use warnings;
$|++;

use lib '../lib';

use Mojolicious::Lite;
use Mojo::ByteStream 'b';

my $t = Test::Mojo->new;

my $app = $t->app;

use_ok('Mojolicious::Plugin::XML::Loy');

ok($app->plugin('XML::Loy'), 'Establish');

# Silence
app->log->level('error');

done_testing;

1;
