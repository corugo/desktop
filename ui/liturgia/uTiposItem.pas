unit uTiposItem;

//Os tipos de item que a liturgia oferece, e o mapa entre o que aparece na
//tela e o que e gravado.
//
//Unit pura, no modelo da regra 5b -- sem VCL, sem Windows, sem referencia a
//form. Porta para o Lazarus sem alterar uma linha.
//
//POR QUE ESTA TABELA EXISTE. Antes, cada tipo era um NUMERO: a ordem do
//cbItens no .dfm, um `case` no btAddClick, as constantes IDX_* do
//cbItensChange e um array no FindIndexForTipo -- quatro lugares que
//precisavam concordar. Na primeira vez que um tipo foi acrescentado eles
//discordaram, e a trilha da tela saiu numa ordem enquanto o mapa estava em
//outra (os botoes sao alTop, e o alTop da VCL empilha POR Top, nao pela
//ordem de criacao).
//
//Agora a ligacao e pelo CODIGO e pelo ROTULO, que nenhuma reordenacao muda.
//ACRESCENTAR UM TIPO E ACRESCENTAR UMA LINHA EM TIPOS_ITEM, e mais nada.

interface

uses
  uItensLiturgia;

type
  TTipoDeItem = record
    codigo: string;        //o que vai para a chave `tipo`
    rotulo: string;        //o que aparece na trilha E no combo
    buscaRapida: Boolean;  //grava escolha = '1': a musica e escolhida no culto
  end;

const
  //A ordem AQUI e a ordem que aparece na trilha da tela, e so isso.
  TIPOS_ITEM: array[0..6] of TTipoDeItem = (
    (codigo: TIPO_ANOTACAO;          rotulo: 'Anotação';
     buscaRapida: False),
    (codigo: TIPO_ARQUIVO;           rotulo: 'Arquivo/Diretório';
     buscaRapida: False),
    (codigo: TIPO_BLOCO_LEGADO;      rotulo: 'Categoria';
     buscaRapida: False),
    (codigo: TIPO_AGENDADOS_LEGADO;  rotulo: 'Itens Agendados';
     buscaRapida: False),
    (codigo: TIPO_MUSICA;            rotulo: 'Música';
     buscaRapida: False),
    //Grava tipo musica igual a linha de cima; quem separa as duas e o
    //buscaRapida, que vira a chave `escolha`.
    (codigo: TIPO_MUSICA;            rotulo: 'Busca rápida';
     buscaRapida: True),
    (codigo: TIPO_SITE;              rotulo: 'Site';
     buscaRapida: False));

//As duas grafias de cada tipo contam como o mesmo tipo: o conversor do .llja
//grava `bloco` e `itens-agendados`, e o form so conhecia as legadas -- item
//vindo de um pacote nao abria para edicao.
function MesmoTipo(const a, b: string): Boolean;

//Qual linha tem este rotulo. -1 quando nenhuma.
function IndiceDoRotulo(const rotulo: string): Integer;

//A linha que corresponde a um item ja gravado. O `escolha` desempata as
//linhas que gravam o mesmo codigo.
function IndiceDoGravado(const codigo: string; busca: Boolean): Integer;

implementation

uses
  System.SysUtils;

function MesmoTipo(const a, b: string): Boolean;

  function ehAgendado(const s: string): Boolean;
  begin
    Result := SameText(s, TIPO_AGENDADOS) or
              SameText(s, TIPO_AGENDADOS_LEGADO);
  end;

begin
  Result := SameText(a, b)
         or (EhDivisoria(a) and EhDivisoria(b))
         or (ehAgendado(a) and ehAgendado(b));
end;

function IndiceDoRotulo(const rotulo: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(TIPOS_ITEM) do
    if SameText(TIPOS_ITEM[i].rotulo, rotulo) then
    begin
      Result := i;
      Exit;
    end;
end;

function IndiceDoGravado(const codigo: string; busca: Boolean): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (Trim(codigo) = '') then
    Exit;

  for i := 0 to High(TIPOS_ITEM) do
    if MesmoTipo(TIPOS_ITEM[i].codigo, codigo) and
       (TIPOS_ITEM[i].buscaRapida = busca) then
    begin
      Result := i;
      Exit;
    end;

  //Codigo que existe na tabela mas nao com este `busca`: vale para liturgia
  //antiga, em que o escolha podia estar ligado num item que hoje seria
  //busca rapida. Melhor abrir no tipo parecido que recusar o item.
  for i := 0 to High(TIPOS_ITEM) do
    if MesmoTipo(TIPOS_ITEM[i].codigo, codigo) then
    begin
      Result := i;
      Exit;
    end;
end;

end.
