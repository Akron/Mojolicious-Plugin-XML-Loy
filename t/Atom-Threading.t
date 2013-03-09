#!/usr/bin/perl

use lib '../lib';

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

my $t = Test::Mojo->new;

my $app = $t->app;

ok($app->plugin('XML::Loy' => {
  new_atom => ['Atom','Atom::Threading']
}), 'Start plugin');

ok(my $entry = $app->new_atom('entry'), 'New atom document');

is($entry->at(':root')->namespace, 'http://www.w3.org/2005/Atom', 'Namespace');

ok(my $person = $entry->new_person(name => 'Zoidberg'), 'New person');

ok($entry->author($person), 'Add author');

is($entry->at('entry > author > name')->text, 'Zoidberg', 'Name');

ok($entry->contributor($person), 'Contributor');

is($entry->at('entry > contributor > name')->text, 'Zoidberg', 'Name');

$entry->id('http://sojolicio.us/blog/2');

is($entry->at('entry')->attrs->{'xml:id'}, 'http://sojolicio.us/blog/2', 'id');
is($entry->at('entry id')->text, 'http://sojolicio.us/blog/2', 'id');

ok($entry->replies('http://sojolicio.us/entry/1/replies' => {
  count => 5,
  updated => '500000'
}), 'Add replies entry');


ok(my $link = $entry->at('link[rel="replies"]'), 'Get replies link');
is($link->attrs('thr:count'), 5, 'Thread Count');
is($link->attrs('thr:updated'), '1970-01-06T18:53:20Z', 'Thread update');
is($link->attrs('href'), 'http://sojolicio.us/entry/1/replies', 'Thread href');
is($link->attrs('type'), 'application/atom+xml', 'Thread type');
is($link->namespace, 'http://www.w3.org/2005/Atom', 'Thread namespace');

$entry->total(8);

is($entry->at('total')->text, 8, 'Total number');
is($entry->at('total')->namespace,
   'http://purl.org/syndication/thread/1.0',
   'Total namespace'
 );

ok($entry->in_reply_to(
  'http://sojolicio.us/blog/1' => {
    href => 'http://sojolicio.us/blog/1x'
  }), 'Add in-reply-to');

is($entry->at('in-reply-to')->namespace,
   'http://purl.org/syndication/thread/1.0', 'In-reply-to namespace');

is($entry->at('in-reply-to')->attrs('href'),
   'http://sojolicio.us/blog/1x', 'In-reply-to href');

is($entry->at('in-reply-to')->attrs('ref'),
   'http://sojolicio.us/blog/1', 'In-reply-to ref');

done_testing;

__END__
