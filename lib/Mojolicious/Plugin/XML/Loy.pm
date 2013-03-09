package Mojolicious::Plugin::XML::Loy;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader;
use XML::Loy;

# Namespace for xml classes and extensions
has namespace => 'XML::Loy';

my %base_classes;

# Register Plugin
sub register {
  my ($plugin, $mojo, $param) = @_;

  # Load parameter from Config file
  if (my $config_param = $mojo->config('XML-Loy')) {
    $param = { %$config_param, %$param };
  };

  # Set Namespace
  if (exists $param->{namespace}) {
    $plugin->namespace(delete $param->{namespace});
  };

  # Start Mojo::Loader instance
  my $loader = Mojo::Loader->new;

  # Create new XML helpers
  foreach my $helper (keys %$param) {
    my @helper = @{ $param->{ $helper } };
    my $base = shift(@helper);

    my $module = $plugin->namespace .
      ($base eq 'Loy' ? '' : "::$base");

    # Load module if not loaded
    unless (exists $base_classes{$module}) {

      # Load base class
      if (my $e = $loader->load($module)) {
	for ($mojo->log) {
	  $_->error("Exception: $e")  if ref $e;
	  $_->error(qq{Unable to load base class "$base"});
	};
	next;
      };

      # Establish mime types
      if ((my $mime   = $module->mime) &&
	    (my $prefix = $module->prefix)) {

	# Apply mime type
	$mojo->types->type($prefix => $mime);
      };

      # module loaded
      $base_classes{$module} = 1;
    };

    # Code generation for ad-hoc helper
    my $code = 'sub { shift;' .
      ' my $doc = ' . $plugin->namespace . '::' . $base . '->new( @_ );';

    # Extend base class
    if (@helper) {
      $code .= '$doc->extension(' .
	join(',', map( '"' . $plugin->namespace . qq{::$_"}, @helper)) .
      ");";
    };
    $code .= 'return $doc; };';

    # Eval code
    my $code_ref = eval $code;

    # Evaluation error
    $mojo->log->fatal($@ . ': ' . $!) and next if $@;

    # Create helper
    $mojo->helper($helper => $code_ref);
  };

  # Plugin wasn't registered before
  unless (exists $mojo->renderer->helpers->{'new_xml'}) {

    # Default 'new_xml' helper
    $mojo->helper(
      new_xml => sub {
	shift;
	return XML::Loy->new( @_ );
      });


    # Add 'render_xml' helper
    $mojo->helper(
      render_xml => sub {
	my ($c, $xml) = @_;
	my $format = 'xml';

	if (my $class = ref $xml) {
	  if (defined $class->mime &&
		defined $class->prefix) {
	    $format = $class->prefix;
	  };
	};

	# render XML with correct mime type
	return $c->render_data(
	  $xml->to_pretty_xml,
	  'format' => $format,
	  @_
	);
      });
  };
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::XML::Loy - XML generation with Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $mojo->plugin(
    'XML::Loy' => {
      namespace    => 'XML::Loy',
      new_activity => ['Atom', 'ActivityStreams'],
      new_hostmeta => ['XRD', 'HostMeta'],
      new_myXML    => ['Loy', 'Atom', 'Atom-Threading']
    });

  # In controller
  my $xml = $c->new_xml('entry');
  my $env = $xml->add('fun:env' => { foo => 'bar' });
  $xml->namespace(fun => 'http://sojolicio.us/ns/fun');
  my $data = $env->add(data => {
    type  => 'text/plain',
    -type => 'armour:30'
  } => <<'B64');
    VGhpcyBpcyBqdXN0IGEgdGVzdCBzdHJpbmcgZm
    9yIHRoZSBhcm1vdXIgdHlwZS4gSXQncyBwcmV0
    dHkgbG9uZyBmb3IgZXhhbXBsZSBpc3N1ZXMu
  B64

  $data->comment('This is base64 data!');

  # Render with correct mime-type
  $c->render_xml($xml);

  # Content-Type: application/xml
  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <entry xmlns:fun="http://sojolicio.us/ns/fun">
  #   <fun:env foo="bar">
  #
  #     <!-- This is base64 data! -->
  #     <data type="text/plain">
  #       VGhpcyBpcyBqdXN0IGEgdGVzdCBzdH
  #       JpbmcgZm9yIHRoZSBhcm1vdXIgdHlw
  #       ZS4gSXQncyBwcmV0dHkgbG9uZyBmb3
  #       IgZXhhbXBsZSBpc3N1ZXMu
  #     </data>
  #   </fun:env>
  # </entry>

  # Use newly created helper
  my $xrd = $c->new_hostmeta;
  $xrd->host('sojolicio.us');
  $c->render_xml($xrd);

  # Content-Type: application/xrd+xml
  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"
  #      xmlns:hm="http://host-meta.net/xrd/1.0"
  #      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  #   <hm:Host>sojolicio.us</hm:Host>
  # </XRD>


=head1 DESCRIPTION

L<Mojolicious::Plugin::XML::Loy> is a plugin to support
XML document generation based on L<XML::Loy>.


=head1 ATTRIBUTES

=head2 C<namespace>

  $xml->namespace('MyXMLFiles::XML');
  print $xml->namespace;

The namespace of all XML plugins.
Defaults to C<XML::Loy>


=head1 METHODS

=head2 C<register>

  # Mojolicious
  $mojo->plugin('XML::Loy' => {
    namespace    => 'MyOwn::XML',
    new_activity => ['Atom', 'ActivityStreams']
  });

  # Mojolicious::Lite
  plugin 'XML::Loy' => {
    new_activity => ['Atom', 'ActivityStreams']
  };

  # In your config file
  {
    'XML-Loy' => {
      new_activity => ['Atom', 'ActivityStreams']
    }
  };

Called when registering the plugin.
Accepts the attributes mentioned above as
well as new xml profiles, defined by the
name of the associated generation helper
and an array reference defining the base
class of the xml document and its extensions.

To create a helper extending the base class,
use 'Loy' as the base class.

  $mojo->plugin('XML::Loy' => {
    new_myXML => ['Loy', 'Atom']
  });

All parameters can be set either on registration or
as part of the configuration file with the key C<XML-Loy>.


=head1 HELPERS

=head2 C<new_xml>

  my $xml = $c->new_xml('entry');
  print $xml->to_pretty_xml;

Creates a new generic L<XML::Loy> document.
All helpers created on registration accept
the parameters as defined in constructors of
the L<XML::Loy> base classes.


=head2 C<render_xml>

  $c->render_xml($xml);
  $c->render_xml($xml, code => 404);

Renders documents based on L<XML::Loy>
using the defined mime-type.


=head1 DEPENDENCIES

L<Mojolicious>,
L<XML::Loy>.

=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-XML-Loy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
