package Onde::Acontece::Controller::Topico::Seguranca::Estado;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub base : Chained('/topico/seguranca/base') PathPart('') CaptureArgs(0) {
  my ( $self, $c ) = @_;
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
  my ( $self, $c, $uf ) = @_;
  $c->forward( 'API::Seguranca::Estado' => object => [$uf] );
}

sub view : Chained('object') : PathPart('') : Args(0) {
  my ( $self, $c ) = @_;
  my $s = $c->stash->{estado} =
    $c->stash->{estado}->related_resultset('municipios')->search(
    { tipo => { -not => undef } },
    { select => [
        'ocorrencias_municipio.ano',
        { sum => 'ocorrencias_municipio.quant' },
        'ocorrencia.tipo'
      ],
      as       => [qw(ano quant tipo)],
      join     => { ocorrencias_municipio => 'ocorrencia' },
      order_by => [qw(ocorrencias_municipio.ano ocorrencia.tipo)],
      group_by => [qw(ocorrencias_municipio.ano ocorrencia.tipo)]
    }
    );
  my %data;
  for my $r ( $s->all ) {
    push @{ $data{ $r->get_column('tipo') } },
      [ $r->get_column('ano'), $r->get_column('quant') ];
  }
  $c->stash->{estado} = \%data;
}

__PACKAGE__->meta->make_immutable;

1;
