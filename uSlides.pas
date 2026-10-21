unit uSlides;

{
  Leitura do conteudo de um pacote de slides do LouvorJA.

  So texto: recebe o conteudo ja lido do slides.lja e devolve o titulo e a
  letra da musica. Nao usa VCL, nao usa a unit Windows e nao conhece o fmMenu,
  entao porta para o Lazarus sem alterar uma linha. Quem abre o zip e o
  chamador.

  O formato e um INI gravado em ANSI, que vive dentro do .slja como slides.lja
  ou solto como .lja:

    [Geral]
    slides=35
    audio=1
    url_musica=audio\Falar com Deus.opus

    [Slide:1]
    tipo=CAPA
    letra=Falar com Deus
    imagem=imagens\hasd_071B.jpg
    tempo=00:00:00

    [Slide:2]
    tipo=LETRA
    letra=Na oracao encontro calma

  O titulo e a letra do slide com tipo=CAPA; a letra da musica e a juncao dos
  slides tipo=LETRA, na ordem em que aparecem. O caractere | separa linhas
  dentro de uma letra, como no copiaArquivoParaSlides.
}

interface

{
  Devolve False quando o texto nao rende nem titulo nem letra: arquivo vazio,
  corrompido ou que nao e pacote de slides.
}
function leDadosSlides(const texto: string; out titulo, letra: string): Boolean;

implementation

uses
  SysUtils, Classes;

function leDadosSlides(const texto: string; out titulo, letra: string): Boolean;
const
  MARCA_SLIDE = '[slide:';
var
  linhas, letras: TStringList;
  i, p: Integer;
  linha, chave, valor, tipoSlide, letraSlide: string;
  emSlide: Boolean;

  //A chave tipo pode vir depois da chave letra, entao o slide so da para ser
  //classificado quando termina.
  procedure fechaSlide;
  begin
    if not emSlide then
      Exit;

    if SameText(Trim(tipoSlide), 'CAPA') then
    begin
      if (titulo = '') then
        titulo := letraSlide;
    end
    else if (letraSlide <> '') then
      letras.Add(letraSlide);

    emSlide := False;
    tipoSlide := '';
    letraSlide := '';
  end;

begin
  Result := False;
  titulo := '';
  letra := '';

  linhas := TStringList.Create;
  letras := TStringList.Create;
  try
    linhas.Text := texto;

    emSlide := False;
    tipoSlide := '';
    letraSlide := '';

    for i := 0 to linhas.Count - 1 do
    begin
      linha := Trim(linhas[i]);
      if (linha = '') then
        Continue;

      if (linha[1] = '[') then
      begin
        fechaSlide;
        emSlide := SameText(Copy(linha, 1, Length(MARCA_SLIDE)), MARCA_SLIDE);
        Continue;
      end;

      //A secao [Geral] so traz contagem, faixa e o liga-desliga do audio
      if not emSlide then
        Continue;

      p := Pos('=', linha);
      if (p <= 1) then
        Continue;

      chave := LowerCase(Trim(Copy(linha, 1, p - 1)));
      valor := Copy(linha, p + 1, MaxInt);

      if (chave = 'tipo') then
        tipoSlide := valor
      else if (chave = 'letra') then
        letraSlide := StringReplace(valor, '|', sLineBreak, [rfReplaceAll]);
    end;

    fechaSlide;

    titulo := Trim(titulo);
    letra := Trim(letras.Text);
    Result := (titulo <> '') or (letra <> '');
  finally
    letras.Free;
    linhas.Free;
  end;
end;

end.
