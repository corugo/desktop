unit uJanela;

//A UNICA WinAPI do menu de musicas novo, concentrada numa funcao com nome
//proprio -- que e o que a regra do porte pede: um ponto para trocar, nao
//quarenta.
//
//A moldura da janela (barra de titulo, botoes de fechar) e a unica coisa que o
//BusinessSkinForm desenhava e que a tela nova NAO reproduz desenhando: ela e do
//sistema. No Windows 10 2004+ um atributo do DWM a pinta de escuro, o que
//basta para a janela nao ficar com uma faixa branca em cima do tema escuro.
//
//As alternativas, se um dia nao bastar: form sem borda com barra desenhada por
//nos (volta a ter de tratar arrastar, redimensionar e snap na mao), ou aceitar
//a moldura do ambiente -- que no Linux e no macOS e o que o usuario espera.

interface

procedure EscureceBarraDeTitulo(janela: THandle);

implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows;

type
  TDwmSetWindowAttribute = function(hwnd: HWND; attr: DWORD; pvAttr: Pointer;
    cb: DWORD): HRESULT; stdcall;

const
  //20 desde o Windows 10 20H1; antes disso, em compilacoes de teste, era 19.
  DWMWA_MODO_ESCURO = 20;
  DWMWA_MODO_ESCURO_ANTIGO = 19;
{$ENDIF}

{$IFDEF MSWINDOWS}
procedure EscureceBarraDeTitulo(janela: THandle);
var
  lib: HMODULE;
  f: TDwmSetWindowAttribute;
  ligado: BOOL;
begin
  //Carga dinamica de proposito: em Windows mais antigo a funcao existe mas o
  //atributo nao, e falhar aqui so deixa a barra clara -- nunca derruba nada.
  lib := LoadLibrary('dwmapi.dll');
  if (lib = 0) then
    Exit;
  try
    f := TDwmSetWindowAttribute(GetProcAddress(lib, 'DwmSetWindowAttribute'));
    if not Assigned(f) then
      Exit;

    ligado := True;
    if (f(janela, DWMWA_MODO_ESCURO, @ligado, SizeOf(ligado)) <> S_OK) then
      f(janela, DWMWA_MODO_ESCURO_ANTIGO, @ligado, SizeOf(ligado));
  finally
    FreeLibrary(lib);
  end;
end;
{$ELSE}
procedure EscureceBarraDeTitulo(janela: THandle);
begin
  //Nada a fazer: a moldura e do ambiente grafico.
end;
{$ENDIF}

end.
