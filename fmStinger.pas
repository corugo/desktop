{
  Stinger de transicao das janelas.

  A animacao original veio como 75 PNGs de 1920x1080. Guardar os quadros sairia
  caro (593 MB em 32 bits, ou 22 ms para decodificar cada um), entao o desenho
  foi reconstruido por geometria: sao tres faixas de cor solida separadas por
  retas paralelas de inclinacao constante.

  A tabela abaixo guarda, para cada quadro, a posicao das quatro bordas medida
  na linha do topo; o resto sai da inclinacao. Os valores estao no espaco
  1920x1080 do material original e sao reescalados para o tamanho da janela, o
  que mantem o desenho nitido em qualquer monitor.

  Da esquerda para a direita, o quadro e:
    [transparente] [painel] [verde] [cinza] [transparente]
  As bordas 'pv', 'vc' e 'ck' percorrem a mesma curva, defasadas de dois
  quadros cada - foi assim que a animacao foi feita, e a tabela preserva isso.

  Entre os quadros 35 e 39 a tela fica 100% coberta: e a janela em que da para
  montar o que estiver por tras sem o usuario ver.
}
unit fmStinger;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, System.Types;

const
  //Quadro a partir do qual a tela esta totalmente coberta
  STINGER_COBERTO = 35;
  STINGER_QUADROS = 75;
  STINGER_FPS     = 60;

type
  TBordasQuadro = record
    kp, pv, vc, ck: Integer;
  end;

  TfStinger = class(TForm)
    procedure FormPaint(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FQuadro: Integer;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  private
    procedure Faixa(x1, x2: Integer; Cor: TColor);
  public
    //Roda do quadro 'de' ate 'ate' no ritmo de STINGER_FPS. O prazo e de
    //relogio: em maquina lenta caem quadros, mas termina na mesma hora
    procedure Roda(de, ate: Integer);
    //Abre a janela cobrindo exatamente a area indicada
    procedure Abre(L, T, La, Al: Integer);
    property Quadro: Integer read FQuadro;
  end;

var
  fStinger: TfStinger;

implementation

{$R *.dfm}

const
  ORIG_L = 1920;   //espaco em que as bordas foram medidas
  ORIG_A = 1080;
  INCLIN = 0.569;  //deslocamento em x por linha
  FORA   = 9999;   //sentinela: borda fora da tela

  COR_PAINEL = TColor($001F1F1F);
  COR_VERDE  = TColor($0091DD39);
  COR_CINZA  = TColor($00484848);

  BORDAS: array[1..STINGER_QUADROS] of TBordasQuadro = (
    (kp: -9999; pv:  -627; vc:  -608; ck:  -585),   //1
    (kp: -9999; pv:  -618; vc:  -597; ck:  -572),   //2
    (kp: -9999; pv:  -608; vc:  -585; ck:  -556),   //3
    (kp: -9999; pv:  -597; vc:  -572; ck:  -539),   //4
    (kp: -9999; pv:  -585; vc:  -556; ck:  -520),   //5
    (kp: -9999; pv:  -572; vc:  -539; ck:  -500),   //6
    (kp: -9999; pv:  -556; vc:  -520; ck:  -479),   //7
    (kp: -9999; pv:  -539; vc:  -500; ck:  -454),   //8
    (kp: -9999; pv:  -520; vc:  -479; ck:  -428),   //9
    (kp: -9999; pv:  -500; vc:  -454; ck:  -400),   //10
    (kp: -9999; pv:  -479; vc:  -428; ck:  -370),   //11
    (kp: -9999; pv:  -454; vc:  -400; ck:  -338),   //12
    (kp: -9999; pv:  -428; vc:  -370; ck:  -302),   //13
    (kp: -9999; pv:  -400; vc:  -338; ck:  -264),   //14
    (kp: -9999; pv:  -370; vc:  -302; ck:  -224),   //15
    (kp: -9999; pv:  -338; vc:  -264; ck:  -180),   //16
    (kp: -9999; pv:  -302; vc:  -224; ck:  -134),   //17
    (kp: -9999; pv:  -264; vc:  -180; ck:   -84),   //18
    (kp: -9999; pv:  -224; vc:  -134; ck:   -31),   //19
    (kp: -9999; pv:  -180; vc:   -84; ck:    27),   //20
    (kp: -9999; pv:  -134; vc:   -31; ck:    88),   //21
    (kp: -9999; pv:   -84; vc:    27; ck:   155),   //22
    (kp: -9999; pv:   -31; vc:    88; ck:   227),   //23
    (kp: -9999; pv:    27; vc:   155; ck:   304),   //24
    (kp: -9999; pv:    88; vc:   227; ck:   388),   //25
    (kp: -9999; pv:   155; vc:   304; ck:   480),   //26
    (kp: -9999; pv:   227; vc:   388; ck:   580),   //27
    (kp: -9999; pv:   304; vc:   480; ck:   690),   //28
    (kp: -9999; pv:   388; vc:   580; ck:   812),   //29
    (kp: -9999; pv:   480; vc:   690; ck:   949),   //30
    (kp: -9999; pv:   580; vc:   812; ck:  1105),   //31
    (kp: -9999; pv:   690; vc:   949; ck:  1287),   //32
    (kp: -9999; pv:   812; vc:  1105; ck:  1506),   //33
    (kp: -9999; pv:   949; vc:  1287; ck:  1794),   //34
    (kp: -9999; pv:  1105; vc:  1506; ck:  9999),   //35
    (kp: -9999; pv:  1287; vc:  1794; ck:  9999),   //36
    (kp: -9999; pv:  1506; vc:  9999; ck:  9999),   //37
    (kp: -9999; pv:  1794; vc:  9999; ck:  9999),   //38
    (kp: -9999; pv:  9999; vc:  9999; ck:  9999),   //39
    (kp:  -544; pv:  9999; vc:  9999; ck:  9999),   //40
    (kp:  -268; pv:  9999; vc:  9999; ck:  9999),   //41
    (kp:   -57; pv:  9999; vc:  9999; ck:  9999),   //42
    (kp:   117; pv:  9999; vc:  9999; ck:  9999),   //43
    (kp:   267; pv:  9999; vc:  9999; ck:  9999),   //44
    (kp:   399; pv:  9999; vc:  9999; ck:  9999),   //45
    (kp:   517; pv:  9999; vc:  9999; ck:  9999),   //46
    (kp:   624; pv:  9999; vc:  9999; ck:  9999),   //47
    (kp:   722; pv:  9999; vc:  9999; ck:  9999),   //48
    (kp:   812; pv:  9999; vc:  9999; ck:  9999),   //49
    (kp:   894; pv:  9999; vc:  9999; ck:  9999),   //50
    (kp:   971; pv:  9999; vc:  9999; ck:  9999),   //51
    (kp:  1042; pv:  9999; vc:  9999; ck:  9999),   //52
    (kp:  1109; pv:  9999; vc:  9999; ck:  9999),   //53
    (kp:  1170; pv:  9999; vc:  9999; ck:  9999),   //54
    (kp:  1228; pv:  9999; vc:  9999; ck:  9999),   //55
    (kp:  1283; pv:  9999; vc:  9999; ck:  9999),   //56
    (kp:  1334; pv:  9999; vc:  9999; ck:  9999),   //57
    (kp:  1382; pv:  9999; vc:  9999; ck:  9999),   //58
    (kp:  1427; pv:  9999; vc:  9999; ck:  9999),   //59
    (kp:  1469; pv:  9999; vc:  9999; ck:  9999),   //60
    (kp:  1509; pv:  9999; vc:  9999; ck:  9999),   //61
    (kp:  1546; pv:  9999; vc:  9999; ck:  9999),   //62
    (kp:  1581; pv:  9999; vc:  9999; ck:  9999),   //63
    (kp:  1614; pv:  9999; vc:  9999; ck:  9999),   //64
    (kp:  1644; pv:  9999; vc:  9999; ck:  9999),   //65
    (kp:  1673; pv:  9999; vc:  9999; ck:  9999),   //66
    (kp:  1700; pv:  9999; vc:  9999; ck:  9999),   //67
    (kp:  1726; pv:  9999; vc:  9999; ck:  9999),   //68
    (kp:  1749; pv:  9999; vc:  9999; ck:  9999),   //69
    (kp:  1772; pv:  9999; vc:  9999; ck:  9999),   //70
    (kp:  1792; pv:  9999; vc:  9999; ck:  9999),   //71
    (kp:  1811; pv:  9999; vc:  9999; ck:  9999),   //72
    (kp:  1829; pv:  9999; vc:  9999; ck:  9999),   //73
    (kp:  1846; pv:  9999; vc:  9999; ck:  9999),   //74
    (kp:  1862; pv:  9999; vc:  9999; ck:  9999)   //75
  );

procedure TfStinger.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  //Sem botao na barra de tarefas e sem roubar foco de quem esta por baixo
  Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE;
  Params.WndParent := 0;
end;

{
  Abre a janela exatamente sobre a area indicada.

  Os limites sao aplicados de novo depois do Show porque o VCL reposiciona a
  janela ao exibi-la: com o DefaultMonitor padrao ela pulava para o monitor do
  formulario ativo, e o stinger aparecia na tela do operador.
}
procedure TfStinger.Abre(L, T, La, Al: Integer);
begin
  SetBounds(L, T, La, Al);
  Show;
  SetBounds(L, T, La, Al);
end;

{
  Desenha uma faixa entre duas bordas.

  Cada borda e uma reta: x no topo vem da tabela, e a base fica deslocada pela
  inclinacao. Como as duas bordas sao paralelas, a faixa e um paralelogramo.
  Os valores sao reescalados do espaco original para o tamanho da janela.
}
procedure TfStinger.Faixa(x1, x2: Integer; Cor: TColor);
var
  p: array[0..3] of TPoint;
  fx: Double;
  d, a: Integer;
begin
  if (x2 <= x1) then
    Exit;

  fx := ClientWidth / ORIG_L;
  a := ClientHeight;
  //Deslocamento da borda entre o topo e a base, ja na escala da janela
  d := Round(INCLIN * ORIG_A * fx);

  //Recorta o que passa muito da tela: poligono gigante nao ajuda ninguem
  if (x1 < -ORIG_L) then x1 := -ORIG_L;
  if (x2 >  ORIG_L * 2) then x2 := ORIG_L * 2;

  p[0] := Point(Round(x1 * fx), 0);
  p[1] := Point(Round(x2 * fx), 0);
  p[2] := Point(Round(x2 * fx) + d, a);
  p[3] := Point(Round(x1 * fx) + d, a);

  Canvas.Brush.Color := Cor;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Style := psClear;
  Canvas.Polygon(p);
end;

//A janela vive so o tempo da transicao: sem isto cada musica deixaria uma para tras
procedure TfStinger.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  fStinger := nil;
end;

procedure TfStinger.FormPaint(Sender: TObject);
var
  b: TBordasQuadro;
begin
  //Preto e a cor-chave: some pela transparencia da janela
  Canvas.Brush.Color := clBlack;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  if (FQuadro < 1) or (FQuadro > STINGER_QUADROS) then
    Exit;

  b := BORDAS[FQuadro];
  Faixa(b.kp, b.pv, COR_PAINEL);
  Faixa(b.pv, b.vc, COR_VERDE);
  Faixa(b.vc, b.ck, COR_CINZA);
end;

procedure TfStinger.Roda(de, ate: Integer);
var
  freq, t0, agora: Int64;
  decorrido, porQuadro: Double;
  q: Integer;
begin
  QueryPerformanceFrequency(freq);
  porQuadro := 1000 / STINGER_FPS;

  if (freq = 0) then
  begin
    FQuadro := ate;
    Repaint;
    Exit;
  end;

  QueryPerformanceCounter(t0);
  repeat
    QueryPerformanceCounter(agora);
    decorrido := (agora - t0) * 1000 / freq;

    q := de + Trunc(decorrido / porQuadro);
    if (q > ate) then
      q := ate;

    if (q <> FQuadro) then
    begin
      FQuadro := q;
      Repaint;
    end;

    if (q < ate) then
      Sleep(1);
  until (q >= ate);
end;

end.
