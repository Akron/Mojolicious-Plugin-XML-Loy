#!/usr/bin/perl
use strict;
use warnings;

$|++;

use lib ('lib', '../lib', '../../lib', '../../../lib');

use Mojo::ByteStream 'b';
use Test::Mojo;
use Mojolicious::Lite;

use Test::More;

my $poco_ns  = 'http://www.w3.org/TR/2011/WD-contacts-api-20110616/';
my $xhtml_ns = 'http://www.w3.org/1999/xhtml';

use_ok('Mojolicious::Plugin::XML::Loy');

# Plugin helper
my $t = Test::Mojo->new;
my $app = $t->app;

ok($app->plugin('XML::Loy' => {
  'new_atom' => ['Atom']
}), 'New plugin');

my $atom = $app->new_atom('feed');

my $atom_string = $atom->to_pretty_xml;
$atom_string =~ s/[\s\r\n]+//g;

is ($atom_string, '<?xmlversion="1.0"encoding="UTF-8'.
                  '"standalone="yes"?><feedxmlns="ht'.
                  'tp://www.w3.org/2005/Atom"/>',
                  'Initial Atom');

ok(my $entry = $atom->entry(id => '#33775'), 'Add entry');

ok(my $person = $atom->new_person(
  name => 'Bender',
  uri => 'http://sojolicio.us/bender'
), 'Add person');

$person->namespace('poco' => $poco_ns);
$person->add('uri', 'http://sojolicio.us/fry');
$person->add('poco:birthday' => '1/1/1970');


ok($entry->author($person), 'Add author');

is($atom->at('author name')->text, 'Bender', 'Author-Name');
is($atom->at('author uri')->text, 'http://sojolicio.us/bender', 'Author-URI');
is($atom->at('author birthday')->text, '1/1/1970', 'Author-Poco-Birthday');
is($atom->at('author birthday')->namespace, $poco_ns, 'Author-Poco-NS');

ok($atom->title(
  type => 'html',
  content => 'Dies ist <b>html</b> Inhalt.'
), 'Add title');

ok($atom->content(
  type => 'xhtml',
  content => 'This is <b>xhtml</b> content!'
), 'Add content');

ok(my $atom2 = $app->new_atom($atom->to_pretty_xml), 'Parse xml');

is($atom2->at('content div b')->text, 'xhtml', 'Pretty Print');

done_testing;

__END__
