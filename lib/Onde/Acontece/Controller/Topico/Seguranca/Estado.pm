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
  my $rs = $c->stash->{estado};
  $c->stash->{ocorrencias} = [$c->model('DB::Ocorrencia')->all];
  $c->stash->{municipios_lista} =
    [ $c->model('DB::Municipio')
      ->search( {}, { order_by => { -asc => 'nome' } } )->all ];

  my $s  =  $rs->related_resultset('municipios')->search(
    {
        'ocorrencias_municipio.ano' => { '<=' => ($c->req->params->{until} || 2010 ) }, 
        tipo => { -not => undef }
    },
    { select => [
        'ocorrencias_municipio.ano',
        { sum => 'ocorrencias_municipio.quant' },
        'ocorrencia.nome'
      ],
      as       => [qw(ano quant tipo)],
      join     => { ocorrencias_municipio => 'ocorrencia' },
      order_by => [qw(ocorrencias_municipio.ano ocorrencia.nome)],
      group_by => [qw(ocorrencias_municipio.ano ocorrencia.nome)]
    }
  );
  my %data;
  for my $r ( $s->all ) {
    push @{ $data{ $r->get_column('tipo') } },
      [ $r->get_column('ano'), $r->get_column('quant') ];
  }
  $c->stash->{estado} = \%data;

  my $m = $rs->related_resultset('municipios')->search(
    {
      'municipios.nome' =>           {-like => ($c->req->params->{municipio} || 'Porto Alegre')},
      'ocorrencias_municipio.ano' => { '<=' => ($c->req->params->{until} || 2010 ) },
      tipo              =>           { -not => undef }
    },
    {
      select => [
        qw(municipios.nome ocorrencia.nome ocorrencias_municipio.ano ocorrencias_municipio.quant)
      ],
      as   => [qw(nome tipo ano quant)],
      join => { ocorrencias_municipio => 'ocorrencia' },
      order_by =>
        [qw(ocorrencias_municipio.ano ocorrencia.nome municipios.nome )],
    }
  );
  my %mun;
  for my $r ( $m->all ) {
    push @{ $mun{ $r->get_column('nome') }{ $r->get_column('tipo') } },
      [ $r->get_column('ano'), $r->get_column('quant') ];
  }
  $c->stash->{mun} = \%mun;



}

__PACKAGE__->meta->make_immutable;

1;
